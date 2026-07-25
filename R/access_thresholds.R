#' Tract "reached"/"covered" population-coverage threshold (percent)
#'
#' A census tract counts as REACHED by a subspecialty at a drive-time band when
#' at least this percent of its (female) population lies within the isochrone --
#' a majority of tract women. `reached == 0` (below this) AND rural defines a
#' subspecialty access desert. This is the binary coverage cut for desert counts,
#' the exclusive-access contrast, and the logistic "reached" outcome.
#' @format Integer scalar, percent in (0, 100].
#' @source isochrones/R/access_thresholds.R; Ryerson 2022 two-vector desert def.
#' @export
TRACT_REACHED_COVERAGE_PCT <- 50L

stopifnot(
  "TRACT_REACHED_COVERAGE_PCT must be a single integer" =
    is.integer(TRACT_REACHED_COVERAGE_PCT) && length(TRACT_REACHED_COVERAGE_PCT) == 1L,
  "TRACT_REACHED_COVERAGE_PCT must be a percent in (0, 100]" =
    TRACT_REACHED_COVERAGE_PCT > 0L && TRACT_REACHED_COVERAGE_PCT <= 100L
)
