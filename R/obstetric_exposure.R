# Obstetric exposure parameter series ---------------------------------------
#
# The cited anchor series for US completed parity by birth cohort and US total
# cesarean rate by year, plus the interpolators that read them and the cohort
# vaginal-delivery exposure derived from the pair.
#
# WHY THEY LIVE HERE
#
# The series and its interpolator existed in two repos with BYTE-IDENTICAL data
# (sha256 193aefef... for the parity anchors) and near-identical code. Two
# copies of one number is one drift away from two different answers to the same
# question, and vaginal-delivery exposure is the primary exposure of the pelvic
# floor disorder models downstream -- the number those models are largely about.
# ARCHITECTURE.md puts definitions here, and every consumer already depends on
# mufflyaccess.
#
# WHAT THIS IS NOT
#
# These are reference PARAMETERS with cited sources, not derived model output.
# Nothing here re-derives a roster, a retirement, or a count -- the boundary the
# charter draws. The band-specific exposure multipliers and demand denominators
# that consume these series stay in the model that defines the bands.
#
# ASSUMPTIONS CARRIED BY cohort_vaginal_exposure()
#
#  * Childbearing is taken as ages 20-35, so a cohort's cesarean fraction is the
#    mean annual rate over its own childbearing window rather than the rate in
#    any single year.
#  * Parity is apportioned between vaginal and cesarean by that fraction. This
#    assumes cesarean risk is independent of birth order within a cohort, which
#    it is not -- repeat cesarean is the dominant indication -- so vaginal
#    deliveries are somewhat UNDERSTATED for high-parity cohorts. Stated here
#    because the assumption is invisible in the returned numbers.
#  * The interpolation clamps outside the anchor range (`rule = 2`) rather than
#    extrapolating: a cohort past the last anchor takes the last anchor's value.

# Childbearing window used to average the cesarean rate across a cohort's own
# fertile years.
OBSTETRIC_CHILDBEAR_AGE_LO <- 20L
OBSTETRIC_CHILDBEAR_AGE_HI <- 35L

# Read a packaged obstetric series. Falls back to the source tree so the
# functions work under load_all() before an install.
.obstetric_extdata <- function(file) {
  p <- system.file("extdata", "obstetric", file, package = "mufflyaccess")
  if (!nzchar(p)) p <- file.path("inst", "extdata", "obstetric", file)
  if (!file.exists(p)) {
    stop(sprintf("obstetric exposure data not found: %s", file), call. = FALSE)
  }
  utils::read.csv(p, stringsAsFactors = FALSE)
}

#' US total-cesarean rate, interpolated across cited anchor years
#'
#' @param years Integer calendar years.
#' @param ces Optional data frame with `year` and `cesarean_rate`, overriding
#'   the packaged anchor series. Present so the interpolation can be tested
#'   against a known series and so a caller can substitute a revised one without
#'   editing the package.
#' @return Numeric cesarean fraction per year, clamped at the anchor range ends.
#' @examples
#' cesarean_rate_for_year(c(1990, 2005, 2020))
#' @export
cesarean_rate_for_year <- function(years, ces = NULL) {
  if (is.null(ces)) ces <- .obstetric_extdata("us_cesarean_rate_by_year.csv")
  .obstetric_check_series(ces, c("year", "cesarean_rate"), "ces")
  ces <- ces[order(ces$year), ]
  stats::approx(ces$year, ces$cesarean_rate, xout = years, rule = 2)$y
}

#' Mean completed parity by birth cohort, interpolated across cited anchors
#'
#' @param cohorts Integer birth-cohort years.
#' @param par Optional data frame with `birth_cohort` and
#'   `mean_completed_parity`, overriding the packaged anchor series.
#' @return Numeric mean completed parity, clamped outside the anchor range.
#' @examples
#' completed_parity_for_cohort(c(1940, 1960, 1980))
#' @export
completed_parity_for_cohort <- function(cohorts, par = NULL) {
  if (is.null(par)) par <- .obstetric_extdata("us_completed_parity_by_cohort.csv")
  .obstetric_check_series(par, c("birth_cohort", "mean_completed_parity"), "par")
  par <- par[order(par$birth_cohort), ]
  stats::approx(par$birth_cohort, par$mean_completed_parity, xout = cohorts, rule = 2)$y
}

#' Cohort vaginal-delivery exposure
#'
#' Mean vaginal and cesarean deliveries per woman for each birth cohort,
#' derived from the completed-parity and cesarean-rate series. See the module
#' header for the assumptions this carries; the repeat-cesarean one in
#' particular means vaginal deliveries are understated for high-parity cohorts.
#'
#' @param cohorts Integer birth cohorts.
#' @return Data frame: `birth_cohort`, `mean_total_parity`,
#'   `cohort_cesarean_fraction`, `mean_vaginal_deliveries`,
#'   `mean_cesarean_deliveries`.
#' @examples
#' cohort_vaginal_exposure(c(1940, 1970))
#' @export
cohort_vaginal_exposure <- function(cohorts) {
  cohorts <- as.integer(cohorts)
  if (!length(cohorts) || anyNA(cohorts)) {
    stop("`cohorts` must be a non-empty integer vector with no NA.", call. = FALSE)
  }
  ces_frac <- vapply(cohorts, function(c0) {
    yrs <- (c0 + OBSTETRIC_CHILDBEAR_AGE_LO):(c0 + OBSTETRIC_CHILDBEAR_AGE_HI)
    mean(cesarean_rate_for_year(yrs))
  }, numeric(1))
  parity <- completed_parity_for_cohort(cohorts)
  data.frame(
    birth_cohort             = cohorts,
    mean_total_parity        = round(parity, 3),
    cohort_cesarean_fraction = round(ces_frac, 4),
    mean_vaginal_deliveries  = round(parity * (1 - ces_frac), 3),
    mean_cesarean_deliveries = round(parity * ces_frac, 3),
    stringsAsFactors = FALSE
  )
}

.obstetric_check_series <- function(d, cols, name) {
  if (!is.data.frame(d) || !all(cols %in% names(d))) {
    stop("`", name, "` must be a data frame with columns: ",
         paste(cols, collapse = ", "), call. = FALSE)
  }
  invisible(d)
}
