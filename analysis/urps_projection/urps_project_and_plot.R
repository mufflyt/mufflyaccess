# analysis/urps_projection/urps_project_and_plot.R
#
# URPS workforce supply projection 2025-2045 across all registered scenarios.
#
# Outputs (written to figures/):
#   urps_projection_headcount.png  — certified headcount by scenario
#   urps_projection_fte.png        — clinical FTE by scenario
#
# Run from the package root:
#   Rscript analysis/urps_projection/urps_project_and_plot.R
#
# Requires: ggplot2, scales

devtools::load_all(quiet = TRUE)
library(ggplot2)

OUT_DIR <- file.path(
  if (nchar(Sys.getenv("RSCRIPT_PATH")) > 0) dirname(Sys.getenv("RSCRIPT_PATH"))
  else {
    args <- commandArgs(trailingOnly = FALSE)
    src  <- sub("--file=", "", args[grep("--file=", args)])
    if (length(src) == 1L && nzchar(src)) dirname(src)
    else "analysis/urps_projection"
  },
  "figures")
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

# ── 1. Baseline cohort ────────────────────────────────────────────────────────
# Distribute 2025 ABOG+ABU roster (1,339) across age × sex × pathway cells.
# Age shape: normal kernel peaked at 43 (ABOG) and 46 (ABU).
# Sex mix: ABOG ~82% female, ABU ~56% female (ACOG / AUA workforce surveys).

make_cohort <- function(n_abog = 1031, n_abu = 308,
                        pf_abog = 0.82, pf_abu = 0.56,
                        mu_abog = 43, sd_abog = 7,
                        mu_abu  = 46, sd_abu  = 8,
                        age_min = 34L, age_max = 72L) {
  ages <- age_min:age_max
  alloc <- function(total, pct_f, mu, sd) {
    w  <- dnorm(ages, mu, sd); w <- w / sum(w)
    nf <- round(total * pct_f       * w)
    nm <- round(total * (1 - pct_f) * w)
    peak     <- which.max(w)
    nf[peak] <- nf[peak] + (round(total * pct_f)       - sum(nf))
    nm[peak] <- nm[peak] + (round(total * (1 - pct_f)) - sum(nm))
    rbind(data.frame(age = ages, sex = "female", n = nf, stringsAsFactors = FALSE),
          data.frame(age = ages, sex = "male",   n = nm, stringsAsFactors = FALSE))
  }
  abog <- alloc(n_abog, pf_abog, mu_abog, sd_abog); abog$pathway <- "ABOG"
  abu  <- alloc(n_abu,  pf_abu,  mu_abu,  sd_abu);  abu$pathway  <- "ABU"
  d    <- rbind(abog, abu)
  d$certified_n <- as.numeric(d$n)
  d[d$certified_n > 0, ]
}

cohort0 <- make_cohort()
stopifnot(abs(sum(cohort0$certified_n) - 1339) <= 2)

# ── 2. Baseline FTE scale (computed once from 2025 practicing cohort) ─────────
prac0 <- urps_apply_lfp(cohort0)
baseline_scale <- urps_fte_scale_sex(data.frame(
  age     = prac0$age,
  sex     = prac0$sex,
  pathway = prac0$pathway,
  n       = prac0$practicing_n,
  stringsAsFactors = FALSE))

# ── 3. Annual entrants entering at age 34 ─────────────────────────────────────
# ABOG: ~70/yr (estimated from 2013→2025 trend: +560 certified / 12 yr)
# ABU:  ~15/yr
ENTRANTS_ABOG_BASE <- 70L
ENTRANTS_ABU_BASE  <- 15L

make_entrants <- function(n_abog, n_abu, pf_abog = 0.85, pf_abu = 0.55) {
  data.frame(
    age         = 34L,
    sex         = c("female", "male", "female", "male"),
    pathway     = c("ABOG",   "ABOG", "ABU",    "ABU"),
    certified_n = c(round(n_abog * pf_abog), round(n_abog * (1 - pf_abog)),
                    round(n_abu  * pf_abu),  round(n_abu  * (1 - pf_abu))),
    stringsAsFactors = FALSE)
}

# ── 4. Projection recurrence ──────────────────────────────────────────────────
project_scenario <- function(scenario_id, years = 2025:2045) {
  sc     <- urps_scenario(scenario_id)
  cohort <- cohort0[, c("age", "sex", "pathway", "certified_n")]

  lapply(years, function(yr) {
    if (yr > 2025) {
      cohort$age <<- cohort$age + 1L
      cohort <<- cohort[cohort$age <= 80, ]

      # urps_retirement_hazard() requires length-1 sex and pathway — loop cells
      for (sx in c("female", "male")) {
        for (pw in c("ABOG", "ABU")) {
          sel <- cohort$sex == sx & cohort$pathway == pw
          if (!any(sel)) next
          h <- urps_retirement_hazard(cohort$age[sel], sx, pw,
                                      retirement_shift_years = sc$retirement_shift_years)
          cohort$certified_n[sel] <<- cohort$certified_n[sel] * (1 - h)
        }
      }

      ents   <- make_entrants(
        round(ENTRANTS_ABOG_BASE * sc$entrant_multiplier),
        round(ENTRANTS_ABU_BASE  * sc$entrant_multiplier))
      cohort <<- rbind(cohort, ents)
    }

    # sc$late_career_fte_onset_age comes back as NA_integer_ when not set;
    # pass NULL to urps_supply_fte_sex() so no late-career adjustment is applied.
    onset      <- sc$late_career_fte_onset_age
    supply_fte <- urps_supply_fte_sex(
      cohort, baseline_scale,
      late_from_age = if (!is.na(onset)) onset else NULL,
      late_factor   = sc$late_career_fte_factor)

    data.frame(year               = yr,
               scenario_id        = scenario_id,
               supply_headcount   = round(sum(cohort$certified_n)),
               supply_clinical_fte = round(supply_fte, 1),
               stringsAsFactors   = FALSE)
  }) |> do.call(what = rbind)
}

scenarios <- c(
  "baseline", "retire_2yr_earlier", "retire_5yr_earlier", "retire_2yr_later",
  "fellowship_plus_10pct", "fellowship_constrained",
  "lower_late_career_fte", "combined_pessimistic", "combined_investment")

proj <- do.call(rbind, lapply(scenarios, project_scenario))

# Historical observed ABOG+ABU headcount (ABOG and ABU annual reports)
observed <- data.frame(
  year                = c(2013, 2014, 2015, 2016, 2017, 2018, 2019,
                           2020, 2021, 2022, 2023, 2025),
  supply_headcount    = c( 655,  830,  932,  968, 1001, 1041, 1089,
                           1099, 1180, 1234, 1306, 1339),
  scenario_id         = "observed",
  supply_clinical_fte = NA_real_,
  stringsAsFactors    = FALSE)

# ── 5. Aesthetics ─────────────────────────────────────────────────────────────
COLORS <- c(
  observed               = "black",
  baseline               = "#2166ac",
  retire_2yr_earlier     = "#d73027",
  retire_5yr_earlier     = "#f46d43",
  retire_2yr_later       = "#1a9641",
  fellowship_plus_10pct  = "#74c476",
  fellowship_constrained = "#fd8d3c",
  lower_late_career_fte  = "#9970ab",
  combined_pessimistic   = "#67001f",
  combined_investment    = "#00441b")

LABELS <- c(
  observed               = "Observed (ABOG+ABU data)",
  baseline               = "Baseline",
  retire_2yr_earlier     = "Retire 2yr earlier",
  retire_5yr_earlier     = "Retire 5yr earlier (stress)",
  retire_2yr_later       = "Retire 2yr later",
  fellowship_plus_10pct  = "Fellowship +10%",
  fellowship_constrained = "Fellowship \u221210%",
  lower_late_career_fte  = "Lower late-career FTE (\u226560)",
  combined_pessimistic   = "Combined pessimistic",
  combined_investment    = "Combined investment")

LTYPES <- c(
  observed               = "solid",
  baseline               = "solid",
  retire_2yr_earlier     = "dashed",
  retire_5yr_earlier     = "dotted",
  retire_2yr_later       = "dashed",
  fellowship_plus_10pct  = "dotdash",
  fellowship_constrained = "longdash",
  lower_late_career_fte  = "dotdash",
  combined_pessimistic   = "solid",
  combined_investment    = "solid")

SIZES <- setNames(
  ifelse(names(COLORS) %in% c("observed", "baseline",
                               "combined_pessimistic", "combined_investment"),
         c(1.3, 1.2, 1.1, 1.1)[match(
           names(COLORS),
           c("observed", "baseline", "combined_pessimistic", "combined_investment"),
           nomatch = 0L) |> pmax(1L)],
         0.8),
  names(COLORS))
# simpler: just set by name
SIZES <- c(observed = 1.3, baseline = 1.2,
           combined_pessimistic = 1.1, combined_investment = 1.1)
SIZES <- setNames(
  ifelse(names(COLORS) %in% names(SIZES), SIZES[names(COLORS)], 0.8),
  names(COLORS))

all_data        <- rbind(proj, observed)
all_data$label  <- LABELS[all_data$scenario_id]
all_data$lsize  <- SIZES[all_data$scenario_id]

# ── 6. Headcount plot ─────────────────────────────────────────────────────────
p_head <- ggplot(all_data,
    aes(x = year, y = supply_headcount,
        colour = scenario_id, linetype = scenario_id,
        linewidth = I(lsize))) +
  geom_vline(xintercept = 2025.3, linetype = "dashed",
             colour = "grey60", linewidth = 0.4) +
  annotate("text", x = 2025.6, y = 2050, label = "Projection \u2192",
           hjust = 0, size = 3, colour = "grey50") +
  geom_line(data = subset(all_data, scenario_id != "observed")) +
  geom_line(data = subset(all_data, scenario_id == "observed"), linewidth = 1.3) +
  geom_point(data = subset(all_data, scenario_id == "observed"),
             shape = 21, fill = "white", size = 2.2, stroke = 1.2) +
  scale_colour_manual(values = COLORS, labels = LABELS, name = NULL) +
  scale_linetype_manual(values = LTYPES, labels = LABELS, name = NULL) +
  scale_x_continuous(breaks = seq(2013, 2045, 4), minor_breaks = NULL) +
  scale_y_continuous(labels = scales::comma,
                     breaks = seq(500, 2200, 200),
                     limits = c(500, 2250)) +
  labs(
    title    = "URPS Workforce Supply Projection 2025\u20132045",
    subtitle = paste0("Certified headcount by scenario  |  ",
                      "Anchored to 2025 ABOG+ABU roster (n\u00a0=\u00a01,339)"),
    x = NULL, y = "Certified providers (ABOG + ABU)") +
  theme_minimal(base_size = 11.5) +
  theme(
    legend.position  = "right",
    legend.key.width = unit(2, "cm"),
    legend.text      = element_text(size = 9),
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(colour = "grey40", size = 10),
    panel.grid.minor = element_blank(),
    axis.text.x      = element_text(angle = 30, hjust = 1))

# ── 7. Clinical FTE plot ──────────────────────────────────────────────────────
p_fte <- ggplot(subset(proj, !is.na(supply_clinical_fte)),
    aes(x = year, y = supply_clinical_fte,
        colour = scenario_id, linetype = scenario_id)) +
  geom_vline(xintercept = 2025.3, linetype = "dashed",
             colour = "grey60", linewidth = 0.4) +
  geom_line(linewidth = 0.9) +
  scale_colour_manual(values = COLORS, labels = LABELS, name = NULL) +
  scale_linetype_manual(values = LTYPES, labels = LABELS, name = NULL) +
  scale_x_continuous(breaks = seq(2025, 2045, 4), minor_breaks = NULL) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title    = "URPS Supply Clinical FTE 2025\u20132045",
    subtitle = paste0("40\u00a0hrs/wk\u00a0=\u00a01.0\u00a0FTE  |  ",
                      "Sex-stratified OLS hours model (urps_fte_sex.R)"),
    x = NULL, y = "Clinical FTE") +
  theme_minimal(base_size = 11.5) +
  theme(
    legend.position  = "right",
    legend.key.width = unit(2, "cm"),
    legend.text      = element_text(size = 9),
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(colour = "grey40", size = 10),
    panel.grid.minor = element_blank(),
    axis.text.x      = element_text(angle = 30, hjust = 1))

# ── 8. Save ───────────────────────────────────────────────────────────────────
ggsave(file.path(OUT_DIR, "urps_projection_headcount.png"), p_head,
       width = 13, height = 7, dpi = 150)
ggsave(file.path(OUT_DIR, "urps_projection_fte.png"), p_fte,
       width = 13, height = 7, dpi = 150)

cat("\nPlots saved to", OUT_DIR, "\n")
cat("  urps_projection_headcount.png\n")
cat("  urps_projection_fte.png\n\n")

# ── 9. Summary table ──────────────────────────────────────────────────────────
cat("2025 and 2045 projected supply by scenario:\n\n")
summary_tbl <- merge(
  proj[proj$year == 2025, c("scenario_id", "supply_headcount", "supply_clinical_fte")],
  proj[proj$year == 2045, c("scenario_id", "supply_headcount", "supply_clinical_fte")],
  by = "scenario_id", suffixes = c("_2025", "_2045"))
summary_tbl$hc_change <- summary_tbl$supply_headcount_2045 - summary_tbl$supply_headcount_2025
summary_tbl$hc_pct    <- round(100 * summary_tbl$hc_change / summary_tbl$supply_headcount_2025, 1)
summary_tbl           <- summary_tbl[order(-summary_tbl$supply_headcount_2045), ]
print(summary_tbl[, c("scenario_id",
                       "supply_headcount_2025", "supply_headcount_2045",
                       "hc_change", "hc_pct",
                       "supply_clinical_fte_2025", "supply_clinical_fte_2045")],
      row.names = FALSE)
