# ==============================================================================
# Parametric-bootstrap confidence intervals for the URPS workforce supply
# projection.
#
# mufflyaccess owns the DEFINITION of the uncertainty model: the parameter-
# sampling distribution (retirement timing, entrant count, LFP intercept) and
# the bootstrap aggregation contract. cliff (or any downstream consumer) owns
# the APPLICATION: supplying the projection function that applies the sampled
# perturbations through its recurrence engine.
#
# Three independent uncertainty sources (HWMM convention):
#   1. Retirement timing  — normal shift to mu (sd = 0.51 yr → ±1 yr at 95%)
#   2. Entrant count      — multiplicative normal scale (cv = 0.077 → ±15% at 95%)
#   3. LFP intercept      — additive normal shift (sd = 0.05)
# ==============================================================================

URPS_PROJECTION_CI_VERSION <- "0.1.0"

local({
  stopifnot(
    "CI version must be semver" =
      grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", URPS_PROJECTION_CI_VERSION)
  )
})

#' Version of the URPS projection CI module
#'
#' @description Semantic version of the parametric-bootstrap confidence interval
#'   module. Bump when the uncertainty model (parameter distributions or
#'   aggregation contract) changes.
#' @format Length-1 character string (e.g. `"0.1.0"`).
#' @seealso [urps_ci_param_draw()], [urps_projection_ci()]
#' @family URPS projection CI
#' @examples
#' URPS_PROJECTION_CI_VERSION
#' @export
URPS_PROJECTION_CI_VERSION

#' Draw one perturbed parameter set for a bootstrap replicate
#'
#' @description Samples one set of perturbation parameters from their marginal
#'   distributions for a single parametric-bootstrap replicate. The returned list
#'   is passed as the `param_draw` argument to the user-supplied `project_fn` in
#'   [urps_projection_ci()].
#'
#' @param retirement_sigma_sd Standard deviation of the retirement-curve shift in
#'   years. Default 0.51 gives ±1 year at the 95% level (1.96 × 0.51 ≈ 1).
#' @param entrant_cv Coefficient of variation for the entrant scale factor.
#'   Default 0.077 gives ±15% at the 95% level (1.96 × 0.077 ≈ 0.15).
#' @param seed Single integer RNG seed, or `NULL` (default) to use the current
#'   RNG state.
#' @return A named list with elements:
#'   \describe{
#'     \item{retirement_sigma_sd}{the `retirement_sigma_sd` argument, passed
#'       through for traceability}
#'     \item{retirement_shift}{`rnorm(1, 0, retirement_sigma_sd)` — additive
#'       year shift applied to the retirement-curve mu}
#'     \item{entrant_scale}{`rnorm(1, 1, entrant_cv)` — multiplicative scale
#'       applied to n_entrants}
#'     \item{lfp_intercept_shift}{`rnorm(1, 0, 0.05)` — additive shift to the
#'       LFP logistic intercept}
#'   }
#' @seealso [urps_projection_ci()], [urps_retirement_params()],
#'   [urps_lfp_params()]
#' @family URPS projection CI
#' @examples
#' urps_ci_param_draw(seed = 1L)
#' # reproducible draw
#' a <- urps_ci_param_draw(seed = 42L)
#' b <- urps_ci_param_draw(seed = 42L)
#' identical(a, b)  # TRUE
#' @export
urps_ci_param_draw <- function(retirement_sigma_sd = 0.51,
                               entrant_cv           = 0.077,
                               seed                 = NULL) {
  stopifnot(
    "[urps_ci_param_draw] retirement_sigma_sd must be a single positive finite scalar" =
      is.numeric(retirement_sigma_sd) && length(retirement_sigma_sd) == 1L &&
      is.finite(retirement_sigma_sd) && retirement_sigma_sd > 0,
    "[urps_ci_param_draw] entrant_cv must be a single positive finite scalar less than 1" =
      is.numeric(entrant_cv) && length(entrant_cv) == 1L &&
      is.finite(entrant_cv) && entrant_cv > 0 && entrant_cv < 1,
    "[urps_ci_param_draw] seed must be NULL or a single integer" =
      is.null(seed) ||
      (length(seed) == 1L && !is.na(seed) &&
       (is.integer(seed) || (is.numeric(seed) && seed == as.integer(seed))))
  )
  if (!is.null(seed)) set.seed(as.integer(seed))
  list(
    retirement_sigma_sd  = retirement_sigma_sd,
    retirement_shift     = stats::rnorm(1L, 0, retirement_sigma_sd),
    entrant_scale        = stats::rnorm(1L, 1, entrant_cv),
    lfp_intercept_shift  = stats::rnorm(1L, 0, 0.05)
  )
}

#' Parametric-bootstrap confidence intervals for the URPS supply projection
#'
#' @description Runs `B` parametric-bootstrap replicates of a user-supplied URPS
#'   projection function and returns per-year, per-scenario quantile bounds on
#'   `supply_headcount` and `supply_clinical_fte`.
#'
#' @details **Three uncertainty sources** are modelled as independent normal draws
#'   applied per replicate (HWMM uncertainty modelling convention):
#'   \itemize{
#'     \item **Retirement timing (±1 yr at 95%):** a normal shift
#'       (`sd = retirement_sigma_sd = 0.51`) is added to the retirement-curve mu
#'       for every sex × pathway cell. This reflects uncertainty in the median
#'       retirement age derived from literature rather than ABOG-specific lapse
#'       records.
#'     \item **Entrant count (±15% at 95%):** a multiplicative normal scale
#'       (`mean = 1, cv = entrant_cv = 0.077`) is applied to the annual entrant
#'       count. This reflects year-to-year fellowship-output uncertainty and
#'       programme-capacity estimation error.
#'     \item **LFP intercept (additive, sd = 0.05):** a normal shift is added to
#'       the logistic LFP intercept for every sex cell, reflecting uncertainty in
#'       the anchor-point participation rates from the 2021 ACOG and 2022 AMA
#'       surveys.
#'   }
#'   The three draws are statistically independent within each replicate. The
#'   caller's `project_fn` is responsible for applying them; [urps_ci_param_draw()]
#'   documents the list contract.
#'
#' @param project_fn A `function(scenario_id, years, param_draw)` that returns a
#'   `data.frame` containing at minimum the columns `year` (integer),
#'   `scenario_id` (character), `supply_headcount` (numeric), and
#'   `supply_clinical_fte` (numeric, may be `NA`). The `param_draw` argument is
#'   the list returned by [urps_ci_param_draw()]; the function applies the
#'   perturbations to its recurrence engine as appropriate.
#' @param scenarios Character vector of registered scenario ids to bootstrap.
#'   Each must pass [is_urps_scenario()]. Default `"baseline"`.
#' @param years Integer vector of projection years. Default `2025:2045`.
#' @param B Number of bootstrap replicates. Must be an integer `>= 10`.
#'   Default `200`.
#' @param seed Single integer RNG seed for reproducibility. Default `42`.
#' @param retirement_sigma_sd Passed to [urps_ci_param_draw()]. Default `0.51`.
#' @param entrant_cv Passed to [urps_ci_param_draw()]. Default `0.077`.
#' @param probs Length-2 numeric giving the lower and upper quantile
#'   probabilities. Both must be in (0, 1) and `probs[1] < probs[2]`. Default
#'   `c(0.025, 0.975)`.
#' @return A `data.frame` with one row per `(year, scenario_id)` combination and
#'   columns:
#'   \describe{
#'     \item{year}{integer projection year}
#'     \item{scenario_id}{character scenario identifier}
#'     \item{lower_headcount_95}{lower quantile of `supply_headcount` across
#'       replicates (at `probs[1]`)}
#'     \item{upper_headcount_95}{upper quantile of `supply_headcount` across
#'       replicates (at `probs[2]`)}
#'     \item{lower_fte_95}{lower quantile of `supply_clinical_fte` across
#'       replicates (at `probs[1]`); `NA` if all replicate FTE values are `NA`}
#'     \item{upper_fte_95}{upper quantile of `supply_clinical_fte` across
#'       replicates (at `probs[2]`); `NA` if all replicate FTE values are `NA`}
#'   }
#' @seealso [urps_ci_param_draw()], [urps_projection_schema()]
#' @family URPS projection CI
#' @examples
#' \dontrun{
#' my_project_fn <- function(scenario_id, years, param_draw) {
#'   # apply param_draw perturbations inside your projection engine
#'   data.frame(
#'     year             = years,
#'     scenario_id      = scenario_id,
#'     supply_headcount = seq(1300, 1200, length.out = length(years)) *
#'       param_draw$entrant_scale,
#'     supply_clinical_fte = NA_real_
#'   )
#' }
#' ci <- urps_projection_ci(my_project_fn, scenarios = "baseline",
#'                           years = 2025:2035, B = 50, seed = 1L)
#' head(ci)
#' }
#' @export
urps_projection_ci <- function(project_fn,
                               scenarios            = "baseline",
                               years                = 2025:2045,
                               B                    = 200,
                               seed                 = 42,
                               retirement_sigma_sd  = 0.51,
                               entrant_cv           = 0.077,
                               probs                = c(0.025, 0.975)) {
  stopifnot(
    "[urps_projection_ci] project_fn must be a function" =
      is.function(project_fn),
    "[urps_projection_ci] B must be a single integer >= 10" =
      length(B) == 1L && !is.na(B) &&
      (is.integer(B) || (is.numeric(B) && B == as.integer(B))) &&
      as.integer(B) >= 10L,
    "[urps_projection_ci] scenarios must be a non-empty character vector" =
      is.character(scenarios) && length(scenarios) >= 1L && !anyNA(scenarios),
    "[urps_projection_ci] all scenarios must be registered in urps_scenarios()" =
      all(is_urps_scenario(scenarios)),
    "[urps_projection_ci] probs must be a length-2 numeric vector in (0, 1) with probs[1] < probs[2]" =
      is.numeric(probs) && length(probs) == 2L && !anyNA(probs) &&
      all(probs > 0 & probs < 1) && probs[1L] < probs[2L]
  )
  B    <- as.integer(B)
  seed <- as.integer(seed)
  set.seed(seed)

  # Pre-allocate collection: for each scenario × year, store B headcount and FTE values.
  # Use a flat list keyed by "<scenario_id>|<year>" for simplicity.
  combo_keys <- as.vector(outer(scenarios, as.character(years),
                                FUN = function(s, y) paste(s, y, sep = "|")))
  headcount_mat <- matrix(NA_real_, nrow = B, ncol = length(combo_keys),
                          dimnames = list(NULL, combo_keys))
  fte_mat       <- matrix(NA_real_, nrow = B, ncol = length(combo_keys),
                          dimnames = list(NULL, combo_keys))

  for (b in seq_len(B)) {
    pd <- urps_ci_param_draw(retirement_sigma_sd = retirement_sigma_sd,
                             entrant_cv           = entrant_cv,
                             seed                 = NULL)
    for (sid in scenarios) {
      result <- project_fn(sid, years, pd)
      if (!is.data.frame(result))
        stop(sprintf(
          "[urps_projection_ci] project_fn must return a data.frame; got %s for scenario '%s' in replicate %d.",
          class(result)[1L], sid, b), call. = FALSE)
      need <- c("year", "scenario_id", "supply_headcount", "supply_clinical_fte")
      miss <- setdiff(need, names(result))
      if (length(miss))
        stop(sprintf(
          "[urps_projection_ci] project_fn result missing column(s): %s (scenario '%s', replicate %d).",
          paste(miss, collapse = ", "), sid, b), call. = FALSE)
      for (yr in years) {
        key  <- paste(sid, as.character(yr), sep = "|")
        rows <- result$scenario_id == sid & result$year == yr
        if (!any(rows)) next
        headcount_mat[b, key] <- result$supply_headcount[rows][1L]
        fte_mat[b, key]       <- result$supply_clinical_fte[rows][1L]
      }
    }
  }

  # Aggregate: quantiles per (scenario, year).
  out_rows <- vector("list", length(combo_keys))
  for (k_idx in seq_along(combo_keys)) {
    key   <- combo_keys[k_idx]
    parts <- strsplit(key, "|", fixed = TRUE)[[1L]]
    sid   <- parts[1L]
    yr    <- as.integer(parts[2L])
    hc    <- headcount_mat[, key]
    fte   <- fte_mat[, key]
    hc_q  <- stats::quantile(hc,  probs = probs, na.rm = TRUE)
    fte_q <- if (all(is.na(fte))) c(NA_real_, NA_real_) else
               stats::quantile(fte, probs = probs, na.rm = TRUE)
    out_rows[[k_idx]] <- data.frame(
      year                = yr,
      scenario_id         = sid,
      lower_headcount_95  = hc_q[[1L]],
      upper_headcount_95  = hc_q[[2L]],
      lower_fte_95        = fte_q[[1L]],
      upper_fte_95        = fte_q[[2L]],
      stringsAsFactors    = FALSE
    )
  }
  do.call(rbind, out_rows)
}
