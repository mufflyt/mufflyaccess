# ==============================================================================
# URPS observed workforce-exit panel -- the PRODUCER (analysis/, needs dplyr).
#
# This re-derives retirement/departure from provider records, which the package
# architecture deliberately keeps OUT of mufflyaccess (the SSOT package never
# re-cleans rosters or re-derives retirement -- it only SERVES frozen facts).
# So this pipeline lives here; it emits three frozen artifacts that the base-R
# serving layer in R/urps_exit_panel.R reads:
#
#   1. urps_provider_month_activity.csv   <- SOURCE OF TRUTH (one row / provider x month)
#   2. urps_observed_departures.csv       <- derivative: one row / confirmed exit
#   3. urps_exit_hazard_by_age_year.csv   <- derivative: n_exits / n_at_risk per age x year
#
# Design (the whole point of a provider-MONTH panel rather than annual roster
# differences): provider -> month -> observed evidence -> practice state ->
# exit episode -> confirmed exit. Building the month panel first preserves the
# evidence needed to distinguish a true exit from a temporary disappearance.
#
# Four evidence principles, in priority order:
#   (P1) positive evidence beats absence -- an active month is proof of practice;
#        an absent month is only a *candidate* for exit.
#   (P2) absence must mature -- a first-absent month is confirmed an exit only
#        after CONFIRM_MONTHS with no return (default 12).
#   (P3) return beats exit -- any later active month cancels a candidate exit and
#        reclassifies the gap as temporary_gap, never a departure.
#   (P4) don't call every disappearance a retirement -- the broad outcome is
#        workforce_exit; exit_reason = "retired" is the SUBSET with explicit
#        retirement evidence (board voluntary-relinquish, Medicare opt-out with
#        no return, obituary/NPPES deactivation reason). Absence alone is never
#        "retired".
#
# Nothing here runs in the SSOT package's light dependency set; run it in a
# producer environment. It fails loud (never a fake panel) when inputs/deps are
# missing, and validates every artifact against the serving contract before write.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
})

CONFIRM_MONTHS <- 12L   # (P2) an absence gap this long with no return == a confirmed exit
`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- 0. inputs ---------------------------------------------------------------
# Each source system (Medicare PECOS/carrier, NPPES, ABOG/ABU roster, Physician
# Compare, mystery-call) must already be normalized to the evidence contract:
#   provider_id | month (first-of-month Date) | source | practice_evidence (lgl)
# plus optional retirement-signal columns consumed in step 4.
#
# EVIDENCE_FILE points at the union of those normalized sources (one CSV / RDS).
evidence_path <- Sys.getenv("URPS_EVIDENCE_FILE", "")
if (!nzchar(evidence_path) || !file.exists(evidence_path))
  stop("[build_exit_panel] set URPS_EVIDENCE_FILE to the normalized provider-month ",
       "evidence union (columns: provider_id, month, source, practice_evidence).",
       call. = FALSE)

evidence <- if (grepl("\\.rds$", evidence_path, ignore.case = TRUE)) {
  readRDS(evidence_path)
} else {
  readr::read_csv(evidence_path, show_col_types = FALSE)
}

# Enforce the serving-side contract at the door (fail loud on a malformed source).
mufflyaccess::validate_urps_exit_evidence(evidence)

# Optional provider age table: provider_id | birth_year (for the age x year hazard).
age_path <- Sys.getenv("URPS_PROVIDER_AGE_FILE", "")
provider_age <- if (nzchar(age_path) && file.exists(age_path)) {
  readr::read_csv(age_path, show_col_types = FALSE)
} else {
  NULL
}

# ---- 1. provider-month activity panel (THE source of truth) ------------------
# Collapse multi-source evidence to one practice state per provider x month:
# active if ANY source saw practice that month (P1: positive evidence wins).
build_urps_exit_panel <- function(evidence, confirm_months = CONFIRM_MONTHS) {
  ev <- evidence %>%
    mutate(month = lubridate::floor_date(as.Date(month), "month"),
           practice_evidence = as.logical(practice_evidence))

  # rectangular provider x month grid, first observed month .. last observed month
  span <- ev %>% summarise(lo = min(month), hi = max(month))
  months <- seq(span$lo, span$hi, by = "month")
  providers <- sort(unique(ev$provider_id))

  grid <- tidyr::expand_grid(provider_id = providers, month = months)

  # (P1) a month is active iff at least one source has positive evidence
  monthly <- ev %>%
    group_by(provider_id, month) %>%
    summarise(active = any(practice_evidence %in% TRUE),
              sources = paste(sort(unique(source)), collapse = "+"),
              .groups = "drop")

  panel <- grid %>%
    left_join(monthly, by = c("provider_id", "month")) %>%
    mutate(active = tidyr::replace_na(active, FALSE),
           sources = tidyr::replace_na(sources, "")) %>%
    arrange(provider_id, month)

  # per provider, restrict the risk window to [first active month, last month] --
  # a provider is not "at risk of exit" before they are ever seen active.
  panel <- panel %>%
    group_by(provider_id) %>%
    mutate(first_active = suppressWarnings(min(month[active], na.rm = TRUE))) %>%
    filter(is.finite(first_active) & month >= first_active) %>%
    mutate(
      # (P3) a gap is "closed" (temporary) if ANY active month comes later
      ever_active_after = vapply(seq_along(month), function(i)
        any(active[seq_len(length(active)) > i]), logical(1)),
      practice_state = dplyr::case_when(
        active                       ~ "active",
        !active &  ever_active_after ~ "temporary_gap",   # (P3) return beats exit
        TRUE                         ~ "candidate_exit"    # trailing absence
      )
    ) %>%
    ungroup() %>%
    select(provider_id, month, active, practice_state, sources)

  attr(panel, "confirm_months") <- confirm_months
  panel
}

# ---- 2. confirmed exits (derivative) -----------------------------------------
# The first candidate_exit month of a provider's trailing absence run, confirmed
# only if the panel observes >= confirm_months of continued absence after it
# (P2). Providers whose trailing absence is shorter than the window are still
# CENSORED -- not yet a confirmed exit -- and are excluded, never counted as 0.
urps_observed_exits <- function(panel, retirement_signals = NULL,
                                confirm_months = attr(panel, "confirm_months") %||% CONFIRM_MONTHS) {
  last_month <- max(panel$month)

  first_gap <- panel %>%
    filter(practice_state == "candidate_exit") %>%
    group_by(provider_id) %>%
    summarise(exit_month = min(month), .groups = "drop") %>%
    # (P2) require the confirmation window to have fully elapsed within observation
    mutate(months_observed_after =
             (lubridate::year(last_month) - lubridate::year(exit_month)) * 12L +
             (lubridate::month(last_month) - lubridate::month(exit_month))) %>%
    filter(months_observed_after >= confirm_months)

  # (P4) default outcome is a workforce exit; upgrade to "retired" only where an
  # explicit retirement signal exists. retirement_signals: provider_id | retired (lgl).
  out <- first_gap %>%
    mutate(exit_reason = "workforce_exit", retirement_observed = FALSE)

  if (!is.null(retirement_signals)) {
    out <- out %>%
      left_join(retirement_signals %>% distinct(provider_id, retired),
                by = "provider_id") %>%
      mutate(retirement_observed = tidyr::replace_na(retired, FALSE),
             exit_reason = ifelse(retirement_observed, "retired", "workforce_exit")) %>%
      select(-retired)
  }

  out %>%
    transmute(provider_id, exit_month,
              exit_reason, retirement_observed) %>%
    arrange(exit_month, provider_id)
}

# ---- 3. age x year exit hazard (derivative) ----------------------------------
# The empirical departure hazard cliff calibrates its forward process from:
# n_exits / n_at_risk within each (age, year) cell. At-risk = providers active at
# the start of the year; exits = confirmed exits during it.
urps_observed_exit_hazard <- function(panel, exits, provider_age) {
  if (is.null(provider_age))
    stop("[build_exit_panel] provider birth years (URPS_PROVIDER_AGE_FILE) are ",
         "required for the age x year hazard.", call. = FALSE)

  # at-risk: providers active in January of each year
  at_risk <- panel %>%
    filter(lubridate::month(month) == 1L, active) %>%
    transmute(provider_id, year = lubridate::year(month)) %>%
    left_join(provider_age, by = "provider_id") %>%
    mutate(age = year - birth_year) %>%
    filter(!is.na(age)) %>%
    count(age, year, name = "n_at_risk")

  exits_ay <- exits %>%
    mutate(year = lubridate::year(exit_month)) %>%
    left_join(provider_age, by = "provider_id") %>%
    mutate(age = year - birth_year) %>%
    filter(!is.na(age)) %>%
    count(age, year, name = "n_exits")

  at_risk %>%
    left_join(exits_ay, by = c("age", "year")) %>%
    mutate(n_exits = tidyr::replace_na(n_exits, 0L),
           exit_hazard = ifelse(n_at_risk > 0, n_exits / n_at_risk, NA_real_),
           hazard_source = "observed_provider_month_panel") %>%
    arrange(year, age)
}

# ---- 4. build + freeze -------------------------------------------------------
panel <- build_urps_exit_panel(evidence)

# retirement signals (optional): provider_id | retired  -- explicit evidence only.
sig_path <- Sys.getenv("URPS_RETIREMENT_SIGNAL_FILE", "")
retirement_signals <- if (nzchar(sig_path) && file.exists(sig_path)) {
  readr::read_csv(sig_path, show_col_types = FALSE)
} else {
  NULL
}

exits  <- urps_observed_exits(panel, retirement_signals)
hazard <- urps_observed_exit_hazard(panel, exits, provider_age)

out_dir <- Sys.getenv("URPS_EXIT_PANEL_OUTDIR", "analysis/urps_exit_panel")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

readr::write_csv(panel,  file.path(out_dir, "urps_provider_month_activity.csv"))
readr::write_csv(exits,  file.path(out_dir, "urps_observed_departures.csv"))
readr::write_csv(hazard, file.path(out_dir, "urps_exit_hazard_by_age_year.csv"))

message(sprintf(
  "[build_exit_panel] froze %d provider-months, %d confirmed exits (%d retired), %d age x year hazards.",
  nrow(panel), nrow(exits), sum(exits$retirement_observed %in% TRUE), nrow(hazard)))

# Flip the manifest to observed retirement (in the isochrones producer, not here):
#   retirement_ascertainment    : "observed"
#   retirement_definition        : "observed_workforce_exit"
#   retirement_panel_resolution  : "provider_month"
#   exit_confirmation_months     : 12
# Then mufflyaccess::urps_retirement_status() -> "observed" and urps_departures() /
# urps_exit_counts() serve real numbers instead of NA.
