#' @title Accessibility-disparity pure statistics (SSOT)
#' @description Pure, dependency-light statistics shared by the isochrones and
#'   twostep accessibility pipelines (population-weighted mean, zero-access share,
#'   Monte-Carlo CI, OLS trend) plus the RUCA rurality map and ACS year/vintage/
#'   variable-code helpers. Promoted verbatim from
#'   isochrones/R/accessibility_stratification.R (guarded there by
#'   tests/testthat/test-accessibility-stratification.R) so isochrones + twostep
#'   share ONE definition. Base R + `stats` only.
#' @name accessibility_stats
NULL

#' Population-weighted mean over all elements (sparse-group safe).
#' @param a numeric values. @param w numeric weights (same length as `a`).
#' @return weighted mean, or NA if the weights sum to 0 / non-finite.
#' @family accessibility-disparity statistics
#' @seealso [zero_access_share()], [mc_weighted_ci()]
#' @examples
#' weighted_mean_all(c(1, 3), c(1, 3))   # 2.5  (population-weighted toward 3)
#' weighted_mean_all(1:3, c(0, 0, 0))    # NA_real_  (zero total weight)
#' @export
weighted_mean_all <- function(a, w) {
  stopifnot(length(a) == length(w))
  sw <- sum(w)
  if (!is.finite(sw) || sw == 0) return(NA_real_)
  sum(a * w) / sw
}

#' Zero-access share (percent of weighted population with access EXACTLY 0).
#' @param access numeric accessibility values. @param w numeric weights.
#' @return percent in [0,100] under non-negative weights, or NA.
#' @family accessibility-disparity statistics
#' @seealso [weighted_mean_all()], [mc_weighted_ci()]
#' @examples
#' # 40 of 50 weighted population lives where access == 0  -> 80%
#' zero_access_share(c(0, 5, 0), c(10, 10, 30))   # 80
#' zero_access_share(c(1, 2, 3), c(1, 1, 1))      # 0  (nobody at exactly 0)
#' @export
zero_access_share <- function(access, w) {
  stopifnot(length(access) == length(w))
  sw <- sum(w)
  if (!is.finite(sw) || sw == 0) return(NA_real_)
  100 * sum(w * (access == 0)) / sw
}

#' Map a USDA RUCA primary code to a binary rurality class.
#' Metropolitan = primary RUCA 1..(RUCA_NONMETRO_MIN-1); Rural = RUCA_NONMETRO_MIN..10.
#' @param code integer-coercible RUCA primary code(s).
#' @return character "Metropolitan"/"Rural" (NA for NA/invalid codes).
#' @seealso [RUCA_NONMETRO_MIN]
#' @family accessibility-disparity statistics
#' @examples
#' rurality_from_ruca(c(1, 4, 10, NA))
#' # "Metropolitan" (1-3), "Rural" (>=4), "Rural" (10), NA
#' @export
rurality_from_ruca <- function(code) {
  code  <- suppressWarnings(as.integer(code))
  metro <- seq_len(RUCA_NONMETRO_MIN - 1L)   # 1:3  (SSOT-derived)
  rural <- RUCA_NONMETRO_MIN:10L             # 4:10 (SSOT-derived)
  out <- ifelse(code %in% metro, "Metropolitan",
         ifelse(code %in% rural, "Rural", NA_character_))
  out[is.na(code)] <- NA_character_
  out
}

#' Census tract boundary vintage for a study year (2010 tracts <=2019, 2020 >=2020).
#' @param year integer-coercible study year(s).
#' @return integer 2010 or 2020, the tract-boundary vintage in force that year.
#' @family accessibility-disparity statistics
#' @seealso [acs_year_of()]
#' @examples
#' tract_vintage_of(c(2019, 2020))   # 2010, 2020  (boundary break at 2020)
#' @export
tract_vintage_of <- function(year) ifelse(as.integer(year) >= 2020L, 2020L, 2010L)

#' ACS 5-year data year for a study year (clamped to the 2013-2022 window).
#' @param year integer-coercible study year(s).
#' @return integer ACS data end-year(s), clamped to [2013, 2022].
#' @family accessibility-disparity statistics
#' @seealso [tract_vintage_of()]
#' @examples
#' acs_year_of(c(2011, 2018, 2025))   # 2013, 2018, 2022  (clamped to the window)
#' @export
acs_year_of <- function(year) pmax(pmin(as.integer(year), 2022L), 2013L)

#' Canonical ACS female-population variable codes (footgun: race tables use _017,
#' full B01001 uses _026).
#' @export
TOTAL_FEMALE_VAR <- "B01001_026"
#' @rdname TOTAL_FEMALE_VAR
#' @export
RACE_FEMALE_VARS <- c(white_nh = "B01001H_017", hispanic = "B01001I_017",
                      black = "B01001B_017", aian = "B01001C_017",
                      asian = "B01001D_017", nhpi = "B01001E_017")

#' Monte-Carlo CI for a population-weighted accessibility statistic.
#' Redraws weights ~ Normal(est, se) B times (unbiased: point estimate lies inside its interval).
#' @param access numeric accessibility values. @param est numeric weight estimates.
#' @param se numeric weight standard errors (ACS MOE / z90). @param stat "mean"/"zero".
#' @param B draws. @param probs interval quantiles. @param seed RNG seed.
#' @return named numeric c(point, lo, hi).
#' @family accessibility-disparity statistics
#' @seealso [weighted_mean_all()], [zero_access_share()]
#' @examples
#' # with zero standard errors the interval collapses to the point estimate
#' mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0, 0), B = 100)
#' # -> c(point = 2.5, lo = 2.5, hi = 2.5)
#' \dontrun{
#' # real use: ACS estimates with their MOE-derived standard errors
#' mc_weighted_ci(access, est = pop_est, se = pop_moe / ACS_MOE_Z90)
#' }
#' @export
mc_weighted_ci <- function(access, est, se, stat = c("mean", "zero"),
                           B = 2000L, probs = c(0.025, 0.975), seed = 1L) {
  stat <- match.arg(stat)
  stopifnot(length(access) == length(est), length(est) == length(se), all(se >= 0 | is.na(se)))
  se[is.na(se)] <- 0
  f <- if (stat == "mean") weighted_mean_all else zero_access_share
  point <- f(access, est)
  set.seed(seed)
  n <- length(est)
  draws <- vapply(seq_len(B), function(b) f(access, stats::rnorm(n, est, se)), numeric(1))
  q <- stats::quantile(draws, probs, na.rm = TRUE)
  c(point = point, lo = unname(q[1]), hi = unname(q[2]))
}

#' OLS temporal trend of an annual series (95% t-interval on the slope).
#' @param year integer years. @param value numeric annual estimates.
#' @return named numeric c(slope, lo, hi, p). All NA when fewer than 3
#'   complete year/value pairs are supplied.
#' @family accessibility-disparity statistics
#' @examples
#' # rising ~1.4 percentage points per year
#' annual_trend(2013:2016, c(10, 11, 13, 14))["slope"]   # ~1.4
#' annual_trend(2013:2014, c(10, 12))                    # all NA (need >=3 points)
#' @export
annual_trend <- function(year, value) {
  d <- data.frame(year = as.numeric(year), value = as.numeric(value))
  d <- d[stats::complete.cases(d), ]
  if (nrow(d) < 3) return(c(slope = NA, lo = NA, hi = NA, p = NA))
  m <- stats::lm(value ~ year, d)
  s <- summary(m)$coefficients["year", ]
  ci <- stats::confint(m)["year", ]
  c(slope = unname(s[["Estimate"]]), lo = unname(ci[1]), hi = unname(ci[2]),
    p = unname(s[["Pr(>|t|)"]]))
}
