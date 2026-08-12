# ==============================================================================
# Observed URPS workforce-exit panel -- the SERVING layer (base R only).
#
# The panel BUILDER (raw Medicare / NPPES / board-roster / mystery-call evidence
# -> provider-month practice states -> confirmed exits -> age x year hazards) is a
# PRODUCER: it re-derives retirement from provider records, which the package
# architecture keeps OUT of mufflyaccess ("no alternative provider-cleaning
# pipeline ... never re-derives rosters, retirement, or dedup"). It therefore
# lives in analysis/urps_exit_panel/ (it needs dplyr/tidyr/lubridate); this file
# only SERVES the frozen, aggregate artifacts it emits, so the SSOT package stays
# base-R light.
#
# The exit episode -- departure from the *practicing workforce* -- is the outcome
# cliff needs; `exit_reason = "retired"` is the subset with explicit retirement
# evidence. Serving stays fail-loud: departures/hazards are unavailable until a
# real observed artifact is configured, mirroring urps_require_retirement_
# ascertained() (an unascertained retirement is never a numeric zero).
# ==============================================================================

.URPS_EXIT_REASONS  <- c("retired", "workforce_exit")

# Resolve a configured artifact path: option first, then env var. NULL when unset.
.urps_exit_source <- function(option, envvar) {
  p <- getOption(option, default = Sys.getenv(envvar, ""))
  if (is.character(p) && length(p) == 1L && nzchar(p)) p else NULL
}

#' Validate a normalized URPS provider-month evidence table
#'
#' @description The tiny contract every source system (Medicare, NPPES, board
#'   roster, Physician Compare, mystery-call) must normalize into before the exit
#'   panel is built: one row per `provider_id` x `month` x `source`, with a
#'   logical `practice_evidence`. Fail-loud so a malformed source can never
#'   silently weaken ascertainment.
#' @param evidence A `data.frame` with columns `provider_id`, `month`, `source`,
#'   `practice_evidence`.
#' @return Invisibly `TRUE` when valid; otherwise an error naming the problem.
#' @seealso [urps_departures()], [urps_require_retirement_ascertained()]
#' @family URPS exit panel
#' @examples
#' ev <- data.frame(provider_id = "1234567890", month = as.Date("2023-01-01"),
#'                  source = "nppes", practice_evidence = TRUE)
#' validate_urps_exit_evidence(ev)
#' @export
validate_urps_exit_evidence <- function(evidence) {
  if (!is.data.frame(evidence))
    stop("[validate_urps_exit_evidence] `evidence` must be a data.frame.", call. = FALSE)
  need <- c("provider_id", "month", "source", "practice_evidence")
  miss <- setdiff(need, names(evidence))
  if (length(miss))
    stop("[validate_urps_exit_evidence] missing column(s): ",
         paste(miss, collapse = ", "), ".", call. = FALSE)
  if (nrow(evidence)) {
    if (!all(is.na(evidence$practice_evidence)) &&
        !is.logical(evidence$practice_evidence) &&
        anyNA(as.logical(evidence$practice_evidence)))
      stop("[validate_urps_exit_evidence] `practice_evidence` must be coercible to logical.",
           call. = FALSE)
    m <- tryCatch(as.Date(evidence$month), error = function(e) NA)
    if (length(m) != nrow(evidence) || anyNA(m))
      stop("[validate_urps_exit_evidence] `month` must parse as a Date.", call. = FALSE)
  }
  invisible(TRUE)
}

# Read + validate a frozen observed-departures artifact (base R).
.urps_read_departures <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path))
    stop("[urps_departures] configured departures artifact not found: ",
         if (is.character(path)) path else "<none>", call. = FALSE)
  d <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  need <- c("provider_id", "exit_month", "exit_reason", "retirement_observed")
  miss <- setdiff(need, names(d))
  if (length(miss))
    stop("[urps_departures] departures artifact missing column(s): ",
         paste(miss, collapse = ", "), ".", call. = FALSE)
  d$exit_month <- as.Date(d$exit_month)
  if (anyNA(d$exit_month))
    stop("[urps_departures] `exit_month` must parse as a Date.", call. = FALSE)
  if (!all(d$exit_reason %in% .URPS_EXIT_REASONS))
    stop("[urps_departures] `exit_reason` must be one of: ",
         paste(.URPS_EXIT_REASONS, collapse = ", "), ".", call. = FALSE)
  d$retirement_observed <- as.logical(d$retirement_observed)
  d$exit_year <- as.integer(format(d$exit_month, "%Y"))
  d
}

#' Observed URPS workforce departures
#'
#' @description Serves the frozen provider-level observed-departure artifact --
#'   one row per confirmed departure from the practicing workforce (a first
#'   absent month confirmed after the panel's ascertainment window). **Fail-loud
#'   by default:** departures are unavailable until an observed artifact is
#'   configured via `options(mufflyaccess.urps_departures_path = ...)` or
#'   `MUFFLYACCESS_URPS_DEPARTURES`; otherwise this calls
#'   [urps_require_retirement_ascertained()], which stops (an unascertained
#'   retirement is never served as zero departures).
#' @param start_year,end_year Optional inclusive `exit_year` bounds.
#' @return A `data.frame`: `provider_id`, `exit_month`, `exit_year`,
#'   `exit_reason` (`"workforce_exit"` / `"retired"`), `retirement_observed`.
#' @seealso [urps_exit_counts()], [urps_exit_hazard_by_age_year()],
#'   [urps_require_retirement_ascertained()]
#' @family URPS exit panel
#' @examples
#' ex <- system.file("extdata", "urps_observed_departures_example.csv",
#'                   package = "mufflyaccess")
#' old <- options(mufflyaccess.urps_departures_path = ex)
#' head(urps_departures())
#' head(urps_departures(start_year = 2022))
#' options(old)
#' @export
urps_departures <- function(start_year = NULL, end_year = NULL) {
  p <- .urps_exit_source("mufflyaccess.urps_departures_path",
                         "MUFFLYACCESS_URPS_DEPARTURES")
  if (is.null(p)) {
    # no observed artifact configured -> fall through the ascertainment guard
    urps_require_retirement_ascertained("provider-level workforce departures")
    stop("[urps_departures] retirement is ascertained but no departures artifact ",
         "is configured; set options(mufflyaccess.urps_departures_path=...).",
         call. = FALSE)
  }
  d <- .urps_read_departures(p)
  if (!is.null(start_year)) d <- d[d$exit_year >= as.integer(start_year), , drop = FALSE]
  if (!is.null(end_year))   d <- d[d$exit_year <= as.integer(end_year),   , drop = FALSE]
  rownames(d) <- NULL
  d
}

#' Observed URPS workforce departures by year
#'
#' @description Aggregates [urps_departures()] to annual observed departure
#'   counts -- the `n_retired` the workforce-count series can finally carry as a
#'   real number instead of `NA`. `retirement_definition = "observed_workforce_exit"`
#'   records that this counts departures from practice, not only self-declared
#'   retirements.
#' @param start_year,end_year Optional inclusive `exit_year` bounds.
#' @return A `data.frame`: `year`, `n_retired`, `n_retired_with_evidence`
#'   (the `exit_reason == "retired"` subset), `retirement_status = "observed"`,
#'   `retirement_definition`.
#' @seealso [urps_departures()], [urps_exit_hazard_by_age_year()]
#' @family URPS exit panel
#' @examples
#' ex <- system.file("extdata", "urps_observed_departures_example.csv",
#'                   package = "mufflyaccess")
#' old <- options(mufflyaccess.urps_departures_path = ex)
#' urps_exit_counts()
#' options(old)
#' @export
urps_exit_counts <- function(start_year = NULL, end_year = NULL) {
  d <- urps_departures(start_year = start_year, end_year = end_year)
  yrs <- sort(unique(d$exit_year))
  data.frame(
    year                     = yrs,
    n_retired                = as.integer(tapply(d$exit_year, d$exit_year, length)[as.character(yrs)]),
    n_retired_with_evidence  = as.integer(vapply(yrs, function(y)
                                 sum(d$exit_year == y & d$retirement_observed %in% TRUE), integer(1))),
    retirement_status        = "observed",
    retirement_definition    = "observed_workforce_exit",
    stringsAsFactors = FALSE)
}

#' Observed URPS exit hazard by age and year
#'
#' @description Serves the frozen empirical departure-hazard artifact --
#'   `n_exits / n_at_risk` per age x year from the provider-month panel's risk
#'   sets. This is what cliff estimates its forward departure process from:
#'   *past* departures are observed here; cliff still *simulates* future
#'   departures, but calibrated to these observed hazards rather than the frozen
#'   2016-2021 curve. Configure via `options(mufflyaccess.urps_exit_hazard_path=...)`
#'   or `MUFFLYACCESS_URPS_EXIT_HAZARD`; fail-loud when unset.
#' @return A `data.frame`: `age`, `year`, `n_at_risk`, `n_exits`, `exit_hazard`
#'   (in \[0, 1\]), `hazard_source`.
#' @seealso [urps_departures()], [urps_exit_counts()]
#' @family URPS exit panel
#' @examples
#' ex <- system.file("extdata", "urps_exit_hazard_by_age_year_example.csv",
#'                   package = "mufflyaccess")
#' old <- options(mufflyaccess.urps_exit_hazard_path = ex)
#' head(urps_exit_hazard_by_age_year())
#' options(old)
#' @export
urps_exit_hazard_by_age_year <- function() {
  p <- .urps_exit_source("mufflyaccess.urps_exit_hazard_path",
                         "MUFFLYACCESS_URPS_EXIT_HAZARD")
  if (is.null(p)) {
    urps_require_retirement_ascertained("observed exit hazards")
    stop("[urps_exit_hazard_by_age_year] no exit-hazard artifact configured; ",
         "set options(mufflyaccess.urps_exit_hazard_path=...).", call. = FALSE)
  }
  if (!file.exists(p))
    stop("[urps_exit_hazard_by_age_year] configured hazard artifact not found: ", p, call. = FALSE)
  h <- utils::read.csv(p, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  need <- c("age", "year", "n_at_risk", "n_exits", "exit_hazard")
  miss <- setdiff(need, names(h))
  if (length(miss))
    stop("[urps_exit_hazard_by_age_year] hazard artifact missing column(s): ",
         paste(miss, collapse = ", "), ".", call. = FALSE)
  if (any(h$n_exits > h$n_at_risk, na.rm = TRUE))
    stop("[urps_exit_hazard_by_age_year] n_exits cannot exceed n_at_risk.", call. = FALSE)
  ok <- is.na(h$exit_hazard) | (h$exit_hazard >= 0 & h$exit_hazard <= 1)
  if (!all(ok))
    stop("[urps_exit_hazard_by_age_year] exit_hazard must be in [0, 1].", call. = FALSE)
  if (is.null(h$hazard_source)) h$hazard_source <- "observed_provider_month_panel"
  h
}
