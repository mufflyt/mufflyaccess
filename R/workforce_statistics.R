# Workforce inferential statistics ------------------------------------------
#
# Small-sample-safe statistics for workforce comparisons: Wilson proportion
# CIs, a two-proportion test with an n >= 30 guard, a rural-vs-metro
# comparison, a subspecialty replacement-gap analysis, and a state
# vulnerability ranking.
#
# WHY THEY LIVE HERE
#
# All five existed in THREE repos at once. cliff and isochrones carried
# byte-identical copies of `calculate_retirement_cliff_statistics.R`; simulation
# had independently improved its own. `calculate_replacement_gap()` differed in
# all three, which is the dangerous case: one name, one apparent meaning, three
# results. ARCHITECTURE.md puts definitions in mufflyaccess, and every one of
# those repos already depends on it, so this is the only home that removes the
# divergence rather than reducing it from three copies to two.
#
# Ported from simulation's implementations, which were the strongest of the
# three:
#
#   * the projection horizon is a PARAMETER. cliff and isochrones hardcode
#     `* 5` beside a comment reading "horizon - reference = 5 years", so
#     changing the horizon silently does not change the arithmetic.
#   * inputs are checked, rather than failing later inside a join.
#   * division goes through safe_divide(), so a subspecialty with zero
#     retirements yields NA and not Inf.
#   * no message() side effect on every call.
#   * deterministic row order in the output.
#
# NO TIDYVERSE. mufflyaccess imports only datasets/jsonlite/stats and sits
# under every other repo in the stack; adding dplyr + tidyr + assertthat here to
# save a few lines would push that cost onto every consumer. The two functions
# that used dplyr are rewritten in base R and their tests assert the same
# results.

# ---- Proportion confidence interval (Wilson score) -------------------------

#' Wilson-score confidence interval for a single proportion
#'
#' The Wilson interval is well-behaved for small samples and for proportions
#' near 0 or 1, which is why it is used here rather than the Wald interval: a
#' rural access-desert proportion is routinely both.
#'
#' @param x Successes (at-risk count).
#' @param n Sample size.
#' @param conf_level Confidence level (default 0.95).
#' @return List: `proportion`, `lower_ci`, `upper_ci` (proportions in `[0, 1]`),
#'   `method`, `note`.
#' @examples
#' calculate_proportion_ci(12, 40)
#' @export
calculate_proportion_ci <- function(x, n, conf_level = 0.95) {
  if (isTRUE(n == 0) || is.na(n)) {
    return(list(proportion = NA_real_, lower_ci = NA_real_, upper_ci = NA_real_,
                method = NA_character_, note = "Zero denominator"))
  }
  prop <- x / n
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  denom <- 1 + z^2 / n
  center <- (prop + z^2 / (2 * n)) / denom
  margin <- z * sqrt(prop * (1 - prop) / n + z^2 / (4 * n^2)) / denom
  list(
    proportion = prop,
    lower_ci = pmax(0, center - margin),
    upper_ci = pmin(1, center + margin),
    method = "Wilson",
    note = sprintf("%.0f%% confidence interval", conf_level * 100)
  )
}

# ---- Two-proportion test with a small-sample guard -------------------------

#' Two-proportion z-test with an n >= 30 guard
#'
#' Refuses to test (returning `method = "descriptive_only"`) when either group
#' is below `min_sample_size`, so a workforce comparison can never report a
#' significant p-value off a handful of physicians. The refusal is a value in
#' the result rather than a warning, so a caller that ignores it still cannot
#' read a p-value that does not exist.
#'
#' @param x1,n1 Successes and total in group 1.
#' @param x2,n2 Successes and total in group 2.
#' @param min_sample_size Minimum per-group n for an inferential test.
#' @return List with `method`, `p_value`, `p_value_formatted`, `significant`,
#'   `note`, and (on a real test) `test_statistic`.
#' @examples
#' calculate_two_prop_test(12, 40, 20, 60)
#' calculate_two_prop_test(2, 5, 3, 6)$method   # "descriptive_only"
#' @export
calculate_two_prop_test <- function(x1, n1, x2, n2, min_sample_size = 30) {
  if (n1 < min_sample_size || n2 < min_sample_size) {
    return(list(method = "descriptive_only", p_value = NA_real_,
                p_value_formatted = "n<30", significant = FALSE,
                note = sprintf("Sample sizes too small for a test (n1=%d, n2=%d)",
                               as.integer(n1), as.integer(n2))))
  }
  if (n1 == 0 || n2 == 0) {
    return(list(method = "insufficient_data", p_value = NA_real_,
                p_value_formatted = "insufficient data", significant = FALSE,
                note = "One or both groups have zero total"))
  }
  tryCatch({
    tr <- stats::prop.test(c(x1, x2), c(n1, n2))
    p <- tr$p.value
    fmt <- if (p < 0.001) "<0.001" else if (p < 0.01) sprintf("%.3f", p) else sprintf("%.2f", p)
    list(method = "prop.test", p_value = p, p_value_formatted = fmt,
         significant = p < 0.05, test_statistic = unname(tr$statistic),
         note = "Two-proportion z-test")
  }, error = function(e) {
    list(method = "test_failed", p_value = NA_real_, p_value_formatted = "test failed",
         significant = FALSE, note = paste("Test error:", conditionMessage(e)))
  })
}

# ---- Rural vs metro comparison ---------------------------------------------

# Percentage that returns NA on a zero denominator, unrounded.
#
# NOT safe_percent(): that rounds to 1 decimal and returns 0 when the
# denominator is zero. Zero is a legitimate rate and "no denominator" is not,
# so collapsing the second onto the first would make an absent comparison look
# like a measured one. Rounding is the caller's business, at the point of
# display.
.ws_percentage <- function(part, total) 100 * safe_divide(part, total, default = NA_real_)

#' Rural-vs-metro at-risk comparison (rates, Wilson CIs, two-proportion test)
#'
#' Bundles the two group rates, their Wilson CIs, and the two-proportion test
#' into one result, so a reported disparity always travels with the interval and
#' the test that qualify it.
#'
#' @param rural_at_risk,rural_total Rural at-risk count and denominator.
#' @param metro_at_risk,metro_total Metro at-risk count and denominator.
#' @return List: `rural`, `metro`, `comparison` (rate difference plus the test).
#' @examples
#' calculate_rural_metro_comparison(30, 100, 40, 200)$comparison$rate_difference_pct
#' @export
calculate_rural_metro_comparison <- function(rural_at_risk, rural_total,
                                             metro_at_risk, metro_total) {
  rural_rate <- .ws_percentage(rural_at_risk, rural_total)
  metro_rate <- .ws_percentage(metro_at_risk, metro_total)
  rural_ci <- calculate_proportion_ci(rural_at_risk, rural_total)
  metro_ci <- calculate_proportion_ci(metro_at_risk, metro_total)
  test <- calculate_two_prop_test(rural_at_risk, rural_total, metro_at_risk, metro_total)

  rate_diff <- if (!is.na(rural_rate) && !is.na(metro_rate)) rural_rate - metro_rate else NA_real_

  list(
    rural = list(at_risk = rural_at_risk, total = rural_total, rate_pct = rural_rate,
                 ci_lower = rural_ci$lower_ci * 100, ci_upper = rural_ci$upper_ci * 100),
    metro = list(at_risk = metro_at_risk, total = metro_total, rate_pct = metro_rate,
                 ci_lower = metro_ci$lower_ci * 100, ci_upper = metro_ci$upper_ci * 100),
    comparison = list(rate_difference_pct = rate_diff, p_value = test$p_value,
                      p_value_formatted = test$p_value_formatted,
                      significant = test$significant, test_method = test$method,
                      note = test$note)
  )
}

# ---- Replacement-gap analysis ----------------------------------------------

#' Subspecialty replacement-gap analysis (retirees vs fellowship graduates)
#'
#' Projects `horizon_years` of graduates against projected retirements per
#' subspecialty and reports the net gap, the replacement ratio, and an adequacy
#' flag.
#'
#' `horizon_years` is a parameter, not a literal. The versions this replaces
#' multiplied by a hardcoded 5 next to a comment explaining that 5 was
#' "horizon - reference", so moving the horizon silently left the arithmetic
#' behind.
#'
#' A subspecialty with no matching graduate rows contributes 0 graduates, not
#' NA: absence of a fellowship is a real zero. A subspecialty with zero
#' retirements yields an NA replacement ratio rather than Inf, because "nobody
#' retiring" has no ratio to report.
#'
#' @param retirees_by_subspec Data frame: `subspecialty`, `retiring_count`.
#' @param fellowship_grads Data frame: `subspecialty`, `graduates`, one row per
#'   observed year.
#' @param horizon_years Projection horizon in years (default 5).
#' @return List: `by_subspecialty` (data frame, ordered by subspecialty) and
#'   `overall` (summary list).
#' @examples
#' calculate_replacement_gap(
#'   data.frame(subspecialty = c("FPMRS", "GO"), retiring_count = c(50, 30)),
#'   data.frame(subspecialty = c("FPMRS", "FPMRS", "GO"), graduates = c(10, 12, 4))
#' )$overall$replacement_ratio
#' @export
calculate_replacement_gap <- function(retirees_by_subspec, fellowship_grads,
                                      horizon_years = 5) {
  stopifnot(is.data.frame(retirees_by_subspec), is.data.frame(fellowship_grads))
  need_r <- c("subspecialty", "retiring_count")
  need_g <- c("subspecialty", "graduates")
  if (!all(need_r %in% names(retirees_by_subspec))) {
    stop("`retirees_by_subspec` needs columns: ", paste(need_r, collapse = ", "),
         call. = FALSE)
  }
  if (!all(need_g %in% names(fellowship_grads))) {
    stop("`fellowship_grads` needs columns: ", paste(need_g, collapse = ", "),
         call. = FALSE)
  }
  .ws_check_scalar_num(horizon_years, "horizon_years", lo = 0)

  # Mean and total graduates per subspecialty, base R.
  subs <- unique(as.character(fellowship_grads$subspecialty))
  annual <- vapply(subs, function(s) {
    mean(fellowship_grads$graduates[fellowship_grads$subspecialty == s], na.rm = TRUE)
  }, numeric(1))
  total <- vapply(subs, function(s) {
    sum(fellowship_grads$graduates[fellowship_grads$subspecialty == s], na.rm = TRUE)
  }, numeric(1))

  by_sub <- retirees_by_subspec[order(as.character(retirees_by_subspec$subspecialty)),
                                , drop = FALSE]
  key <- as.character(by_sub$subspecialty)
  by_sub$annual_grads <- unname(annual[key])
  by_sub$total_grads  <- unname(total[key])
  # A subspecialty with no graduate rows has none, which is 0 and not unknown.
  by_sub$annual_grads[is.na(by_sub$annual_grads)] <- 0
  by_sub$total_grads[is.na(by_sub$total_grads)]   <- 0

  by_sub$projected_grads      <- by_sub$annual_grads * horizon_years
  by_sub$replacement_ratio    <- safe_divide(by_sub$projected_grads,
                                             by_sub$retiring_count, default = NA_real_)
  by_sub$net_gap              <- by_sub$retiring_count - by_sub$projected_grads
  by_sub$gap_percentage       <- .ws_percentage(by_sub$net_gap, by_sub$retiring_count)
  by_sub$adequate_replacement <- by_sub$replacement_ratio >= 1
  rownames(by_sub) <- NULL

  total_retiring <- sum(by_sub$retiring_count, na.rm = TRUE)
  total_proj     <- sum(by_sub$projected_grads, na.rm = TRUE)
  overall_gap    <- total_retiring - total_proj

  list(
    by_subspecialty = by_sub,
    overall = list(
      total_retiring = total_retiring,
      total_graduates_projected = total_proj,
      net_gap = overall_gap,
      gap_percentage = .ws_percentage(overall_gap, total_retiring),
      replacement_ratio = safe_divide(total_proj, total_retiring, default = NA_real_),
      horizon_years = horizon_years
    )
  )
}

# ---- State vulnerability ranking -------------------------------------------

#' Rank states by workforce vulnerability
#'
#' Ranks states by the percent of active providers lost if the at-risk cohort
#' retires, and reports a `vulnerability_score` weighting that loss by
#' `log10(count_active)` so a large state's proportional loss outweighs a tiny
#' state's. Ordering is by `pct_loss_if_retire`, not by the score: the score is
#' reported for context, and silently ranking by a different quantity than the
#' one named would be the sort of thing nobody notices.
#'
#' @param state_impacts Data frame with `state`, `count_active`,
#'   `count_at_risk`, `pct_loss_if_retire`, `zero_coverage_if_retire`.
#' @param top_n Number of top-vulnerable states to return.
#' @return Data frame of the `top_n` most vulnerable states plus
#'   `vulnerability_score`.
#' @examples
#' impacts <- data.frame(
#'   state = c("CA", "TX", "WY"),
#'   count_active = c(120, 90, 3),
#'   count_at_risk = c(20, 25, 2),
#'   pct_loss_if_retire = c(16.7, 27.8, 66.7),
#'   zero_coverage_if_retire = c(FALSE, FALSE, TRUE)
#' )
#' calculate_state_vulnerability(impacts, top_n = 2)
#' @export
calculate_state_vulnerability <- function(state_impacts, top_n = 10) {
  stopifnot(is.data.frame(state_impacts))
  needed <- c("state", "count_active", "count_at_risk", "pct_loss_if_retire",
              "zero_coverage_if_retire")
  if (!all(needed %in% names(state_impacts))) {
    stop("`state_impacts` needs columns: ", paste(needed, collapse = ", "),
         call. = FALSE)
  }
  .ws_check_scalar_num(top_n, "top_n", lo = 1)

  d <- state_impacts[!is.na(state_impacts$pct_loss_if_retire), , drop = FALSE]
  d$vulnerability_score <- d$pct_loss_if_retire * log10(pmax(1, d$count_active))
  d <- d[order(-d$pct_loss_if_retire), , drop = FALSE]
  d <- utils::head(d, top_n)
  rownames(d) <- NULL
  d[, c(needed, "vulnerability_score"), drop = FALSE]
}

# Scalar guard, local to this file so it adds no dependency.
.ws_check_scalar_num <- function(x, name, lo = -Inf, hi = Inf) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < lo || x > hi) {
    stop("`", name, "` must be a single finite number in [", lo, ", ", hi, "]; got ",
         paste(utils::capture.output(utils::str(x)), collapse = " "), call. = FALSE)
  }
  invisible(x)
}
