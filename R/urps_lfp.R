# ==============================================================================
# URPS labor force participation (LFP) model.
#
# mufflyaccess owns the DEFINITION of the logistic LFP model: the parameter
# table (intercept, b_age by sex) and the functions that evaluate it.
# cliff owns the APPLICATION: multiplying the certified headcount by urps_p_active()
# to get the effective practicing count in each projection year.
#
# DISTINCTION FROM urps_retirement.R:
#   urps_retirement_hazard() — PERMANENT exit: the annual probability a provider
#     leaves the workforce forever. Drives the headcount survival curve.
#   urps_p_active()          — CONDITIONAL participation: given a provider is
#     still certified (not permanently retired), the probability they are
#     actively practicing this year. Captures sabbaticals, temporary
#     withdrawals, leaves of absence, and gradual part-time transitions that
#     do not appear as retirements in the certification record.
#
# In cliff's projection recurrence, both models compose:
#   practicing_headcount = certified_headcount × urps_p_active(age, sex)
#   supply_clinical_fte  = sum(n_i × p_active_i × urps_fte_weight_sex(age_i, sex_i, pathway_i))
#
# Model: logistic regression of P(active | age, sex)
#   logit(P) = intercept + b_age × age
#   P(active) = 1 / (1 + exp(-(intercept + b_age × age)))
#
# Parameters calibrated from two anchor points per sex derived from ACOG 2021
# and AMA 2022 workforce surveys. calibration_status = "calibrated_from_literature".
#
# Anchor points (proportion currently practicing | still certified):
#   Female: P(active | age=40) = 0.97,  P(active | age=65) = 0.78
#   Male:   P(active | age=40) = 0.98,  P(active | age=65) = 0.85
#
# Sources:
#   ACOG 2021 Workforce Survey (active vs. inactive by age and sex, OB/GYN subspecialists)
#   AMA 2022 Physician Practice Benchmark Survey (labor force status by age and sex)
#   IHS Markit HWMM v5.19.20, Exhibit 16 (odds ratios predicting probability active)
# ==============================================================================

.URPS_LFP_VERSION <- "1.0.0"

.urps_lfp_params_df <- function() {
  data.frame(
    sex                = c("female", "male"),
    intercept          = c(7.0127903962, 7.3433710865),
    b_age              = c(-0.0884172927, -0.0862887697),
    anchor_age_lo      = c(40L, 40L),
    anchor_p_lo        = c(0.97, 0.98),
    anchor_age_hi      = c(65L, 65L),
    anchor_p_hi        = c(0.78, 0.85),
    calibration_status = "calibrated_from_literature",
    stringsAsFactors   = FALSE
  )
}

local({
  d <- .urps_lfp_params_df()

  p_logistic <- function(intercept, b_age, age) {
    1 / (1 + exp(-(intercept + b_age * age)))
  }

  stopifnot(
    "LFP params must have exactly 2 rows (female and male)" =
      nrow(d) == 2L,
    "sex must be 'female' and 'male'" =
      setequal(d$sex, c("female", "male")),
    "required columns present" =
      all(c(
        "intercept", "b_age", "anchor_age_lo", "anchor_p_lo",
        "anchor_age_hi", "anchor_p_hi", "calibration_status"
      ) %in% names(d)),
    "b_age must be negative (participation declines with age)" =
      all(d$b_age < 0),
    "anchor P values must be in (0, 1)" =
      all(d$anchor_p_lo > 0 & d$anchor_p_lo < 1 &
        d$anchor_p_hi > 0 & d$anchor_p_hi < 1),
    "anchor_p_lo must exceed anchor_p_hi (participation falls with age)" =
      all(d$anchor_p_lo > d$anchor_p_hi),
    "male P(active) must exceed female P(active) at anchor ages" = {
      r_f <- d[d$sex == "female", ]
      r_m <- d[d$sex == "male", ]
      p_logistic(r_m$intercept, r_m$b_age, r_m$anchor_age_lo) >
        p_logistic(r_f$intercept, r_f$b_age, r_f$anchor_age_lo) &&
        p_logistic(r_m$intercept, r_m$b_age, r_m$anchor_age_hi) >
          p_logistic(r_f$intercept, r_f$b_age, r_f$anchor_age_hi)
    },
    "coefficients must reproduce low anchor P within 1e-6" = {
      tol <- 1e-6
      all(mapply(
        function(a, p, int, b) {
          abs(p_logistic(int, b, a) - p) < tol
        },
        d$anchor_age_lo, d$anchor_p_lo, d$intercept, d$b_age
      ))
    },
    "coefficients must reproduce high anchor P within 1e-6" = {
      tol <- 1e-6
      all(mapply(
        function(a, p, int, b) {
          abs(p_logistic(int, b, a) - p) < tol
        },
        d$anchor_age_hi, d$anchor_p_hi, d$intercept, d$b_age
      ))
    },
    "LFP version must be semver" =
      grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", .URPS_LFP_VERSION)
  )
})

#' Version of the URPS labor force participation model
#'
#' @description Semantic version of the logistic LFP parameter set. Bump when
#'   anchor points or coefficients change.
#' @format Length-1 character string (e.g. `"1.0.0"`).
#' @seealso [urps_lfp_params()], [urps_p_active()]
#' @family URPS LFP
#' @examples
#' URPS_LFP_VERSION
#' @export
URPS_LFP_VERSION <- .URPS_LFP_VERSION

#' Literature-calibrated URPS labor force participation parameters
#'
#' @description Logistic regression coefficients (intercept, b_age) predicting
#'   the probability that a board-certified URPS provider is actively practicing
#'   in a given year, conditional on not having permanently retired. Stratified
#'   by sex.
#'
#' @details **Distinction from the retirement model:** [urps_retirement_hazard()]
#'   models the annual probability of *permanent* exit. `urps_p_active()` models
#'   the conditional probability of *current* practice given still-certified —
#'   capturing sabbaticals, leaves of absence, and part-time transitions that
#'   don't register as retirements. Both compose in cliff's recurrence:
#'   `practicing_n = certified_n × urps_p_active(age, sex)`.
#'
#'   **Calibration:** `"calibrated_from_literature"` — derived from two anchor
#'   points per sex (see `anchor_*` columns) from ACOG 2021 and AMA 2022 surveys.
#'   Individual ABOG lapse records or a URPS practice survey would sharpen them.
#'
#' @return A `data.frame` with columns `sex`, `intercept`, `b_age`,
#'   `anchor_age_lo`, `anchor_p_lo`, `anchor_age_hi`, `anchor_p_hi`, and
#'   `calibration_status`. Carries attributes `source`, `formula`.
#' @seealso [urps_p_active()], [urps_lfp_curve()], [URPS_LFP_VERSION],
#'   [urps_retirement_hazard()]
#' @family URPS LFP
#' @examples
#' urps_lfp_params()
#' attr(urps_lfp_params(), "formula")
#' @export
urps_lfp_params <- function() {
  d <- .urps_lfp_params_df()
  attr(d, "source") <- paste(
    "ACOG 2021 Workforce Survey (active vs. inactive by age and sex, OB/GYN subspecialists);",
    "AMA 2022 Physician Practice Benchmark Survey (labor force status by age and sex);",
    "IHS Markit HWMM v5.19.20 Exhibit 16 (odds ratios predicting probability active).",
    "Sharpen with: ABOG lapse/recertification panel or URPS practice survey."
  )
  attr(d, "formula") <-
    "logit(P(active)) = intercept + b_age * age;  P = 1 / (1 + exp(-logit))"
  d
}

# Internal: validate sex and return row indices into the params table.
# Vectorized: sex may be length-1 or the same length as age.
.urps_lfp_sex_index <- function(sex) {
  if (!is.character(sex) || length(sex) < 1L) {
    stop("[urps_lfp] `sex` must be a non-empty character vector.", call. = FALSE)
  }
  d <- .urps_lfp_params_df()
  idx <- match(sex, d$sex)
  bad <- unique(sex[is.na(idx)])
  if (length(bad)) {
    stop(sprintf(
      "[urps_lfp] unknown sex value(s): %s (must be 'female' or 'male').",
      paste(bad, collapse = ", ")
    ), call. = FALSE)
  }
  idx
}

#' P(actively practicing) given age and sex
#'
#' @description The logistic labor force participation probability:
#'   `P(active | age, sex) = 1 / (1 + exp(-(intercept + b_age * age)))`.
#'   Captures sabbaticals, leaves of absence, and part-time transitions that
#'   do not appear as permanent retirements in the certification record.
#'   Vectorized over both `age` and `sex`.
#'
#' @details **How cliff uses this:** multiply the certified (not permanently
#'   retired) headcount by `urps_p_active()` to get the practicing count before
#'   applying the FTE weight:
#'   ```
#'   practicing_n    <- certified_n * urps_p_active(age, sex)
#'   supply_fte_cell <- practicing_n * urps_fte_weight_sex(age, sex, pathway, ...)
#'   ```
#'
#' @param age Numeric or integer vector of ages. Must be non-empty.
#' @param sex Character vector of `"female"` / `"male"` values, recycled
#'   against `age`.
#' @return Numeric vector in (0, 1) the same length as `max(length(age), length(sex))`.
#' @seealso [urps_lfp_params()], [urps_lfp_curve()], [urps_retirement_hazard()],
#'   [urps_fte_weight_sex()]
#' @family URPS LFP
#' @examples
#' urps_p_active(40, "female") # ~0.97
#' urps_p_active(65, "male") # ~0.85
#' urps_p_active(35:75, "female")
#' # mixed-sex cohort:
#' urps_p_active(c(45, 50), c("female", "male"))
#' @export
urps_p_active <- function(age, sex) {
  if (!(is.numeric(age) || is.integer(age)) || length(age) < 1L) {
    stop("[urps_p_active] `age` must be a non-empty numeric or integer vector.",
      call. = FALSE
    )
  }
  d <- .urps_lfp_params_df()
  idx <- .urps_lfp_sex_index(sex)
  a <- as.numeric(age)
  logit <- d$intercept[idx] + d$b_age[idx] * a
  1 / (1 + exp(-logit))
}

#' Full URPS labor force participation curve as a data.frame
#'
#' @description Returns `P(active | age, sex)` over a specified age range as a
#'   `data.frame(age, p_active)`. Convenience wrapper for cliff to tabulate or
#'   plot the LFP curve for one sex.
#'
#' @param sex `"female"` or `"male"` (length-1).
#' @param age_range Integer or numeric vector of ages (default `35:80`).
#' @return A `data.frame` with columns `age` (integer) and `p_active` (numeric,
#'   in (0, 1)). One row per element of `age_range`.
#' @seealso [urps_p_active()], [urps_lfp_params()]
#' @family URPS LFP
#' @examples
#' head(urps_lfp_curve("female"))
#' urps_lfp_curve("male", age_range = 40:70)
#' @export
urps_lfp_curve <- function(sex, age_range = 35:80) {
  if (!(is.numeric(age_range) || is.integer(age_range)) || length(age_range) < 1L) {
    stop("[urps_lfp_curve] `age_range` must be a non-empty numeric or integer vector.",
      call. = FALSE
    )
  }
  data.frame(
    age = as.integer(age_range),
    p_active = urps_p_active(age_range, sex),
    stringsAsFactors = FALSE
  )
}

#' Apply LFP to a certified cohort to obtain the practicing headcount
#'
#' @description Multiplies `certified_n` by `urps_p_active(age, sex)` to produce
#'   `practicing_n` — the expected number of providers actively practicing in a
#'   given year conditional on still holding certification. This is the first step
#'   of the supply pipeline before applying the FTE weight:
#'
#'   ```
#'   cohort <- urps_apply_lfp(cohort)   # certified_n -> practicing_n
#'   fte    <- urps_effective_fte_sex(   # practicing_n -> supply_clinical_fte
#'               data.frame(..., n = cohort$practicing_n), scale)
#'   ```
#'
#'   Or call [urps_supply_fte_sex()] to do both steps in one call.
#'
#' @param cohort A `data.frame` with columns `age` (numeric/integer), `sex`
#'   (`"female"` / `"male"`), and `certified_n` (numeric). Other columns are
#'   passed through unchanged.
#' @return The same `data.frame` with a new column `practicing_n` =
#'   `certified_n * urps_p_active(age, sex)`. Any existing `practicing_n`
#'   column is overwritten.
#' @seealso [urps_p_active()], [urps_supply_fte_sex()], [urps_effective_fte_sex()]
#' @family URPS LFP
#' @examples
#' cohort <- data.frame(
#'   age = c(45L, 62L, 45L, 62L),
#'   sex = c("female", "female", "male", "male"),
#'   pathway = c("ABOG", "ABOG", "ABU", "ABU"),
#'   certified_n = c(350, 150, 100, 40)
#' )
#' urps_apply_lfp(cohort)
#' @export
urps_apply_lfp <- function(cohort) {
  need <- c("age", "sex", "certified_n")
  miss <- setdiff(need, names(cohort))
  if (length(miss)) {
    stop(sprintf(
      "[urps_apply_lfp] missing required column(s): %s.",
      paste(miss, collapse = ", ")
    ), call. = FALSE)
  }
  cohort$practicing_n <- cohort$certified_n * urps_p_active(cohort$age, cohort$sex)
  cohort
}
