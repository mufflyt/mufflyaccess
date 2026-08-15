# ==============================================================================
# URPS sex-stratified FTE hours model.
#
# Extends the binary-pathway FTE model in urps_fte.R with sex stratification,
# following the OLS hours-worked approach in IHS Markit HWMM Exhibits 14-15.
# Model: weekly patient care hours as a quadratic function of age, fit
# separately for female and male providers.
#
#   hours(age, sex) = intercept + b_age * age + c_age_sq * age^2
#
# FTE weight:
#   urps_fte_weight_sex(age, sex, pathway, ...) =
#     max(hours(age, sex), 0) / URPS_FTE_REFERENCE_HOURS_PER_WEEK
#     * URPS_FTE_PATHWAY_CLINICAL_TIME[pathway]
#     * late_career_factor (if scenario lever active)
#
# URPS_FTE_REFERENCE_HOURS_PER_WEEK = 40 (standard medical FTE: 40 hrs/wk = 1.0
# FTE). A URPS subspecialist at career peak works > 1.0 FTE by this definition.
#
# This model COEXISTS with urps_fte_weight() / urps_fte_age_curve() (unchanged).
# urps_fte_weight_sex() is preferred when sex data are available in the cliff
# provider cohort; urps_fte_weight() remains for callers without per-provider sex.
#
# Calibration: coefficients are fit by quadratic regression to three anchor
# points per sex, derived from ACOG and AMA workforce surveys. They carry
# calibration_status = "calibrated_from_literature"; ABOG-specific lapse or
# practice survey data would sharpen them.
#
# Anchor points (weekly patient care hours; ACOG 2021 + AMA 2022 Benchmark Survey,
# OB/GYN subspecialists):
#   Male:   age 35 -> 50 hrs, age 47 -> 55 hrs, age 65 -> 38 hrs
#   Female: age 35 -> 43 hrs, age 45 -> 47 hrs, age 65 -> 28 hrs
#
# Sources:
#   ACOG 2021 Workforce Survey (hours by age and sex, OB/GYN subspecialists)
#   AMA 2022 Physician Practice Benchmark Survey (weekly patient care hours)
#   IHS Markit HWMM v5.19.20, Exhibits 14-15 (OLS hours-worked model structure)
# ==============================================================================

.URPS_FTE_SEX_HOURS_VERSION <- "1.0.0"

#' Standard medical FTE reference (hours per week)
#'
#' @description The denominator for the sex-stratified FTE weight: 40 hours per
#'   week = 1.0 FTE. A subspecialist working more than 40 hours per week at peak
#'   career has an FTE weight > 1. Used by [urps_fte_weight_sex()].
#' @format Length-1 numeric.
#' @seealso [urps_fte_weight_sex()], [urps_fte_sex_hours_params()]
#' @family URPS FTE sex
#' @examples
#' URPS_FTE_REFERENCE_HOURS_PER_WEEK
#' @export
URPS_FTE_REFERENCE_HOURS_PER_WEEK <- 40.0

# Internal: single source of OLS coefficients, derived by fitting a quadratic
# to three anchor points per sex (see file header). Never define numbers twice.
.urps_fte_sex_hours_params_df <- function() {
  data.frame(
    sex                = c("female", "male"),
    intercept          = c(-41.8750000000, -39.2175925926),
    b_age              = c(4.0000000000, 4.1370370370),
    c_age_sq           = c(-0.0450000000, -0.0453703704),
    anchor_age_lo      = c(35L, 35L),
    anchor_hours_lo    = c(43.0, 50.0),
    anchor_age_peak    = c(45L, 47L),
    anchor_hours_peak  = c(47.0, 55.0),
    anchor_age_hi      = c(65L, 65L),
    anchor_hours_hi    = c(28.0, 38.0),
    calibration_status = "calibrated_from_literature",
    stringsAsFactors   = FALSE
  )
}

# Load-time validation.
local({
  d <- .urps_fte_sex_hours_params_df()
  ref <- URPS_FTE_REFERENCE_HOURS_PER_WEEK

  # Derived values used in checks.
  peak_age <- function(b, c) -b / (2 * c)
  peak_hrs <- function(a, b, c) {
    pa <- peak_age(b, c)
    a + b * pa + c * pa^2
  }
  evaluate <- function(a, b, c, age) a + b * age + c * age^2
  r_f <- d[d$sex == "female", ]
  r_m <- d[d$sex == "male", ]

  stopifnot(
    "sex hours params must have exactly 2 rows (female and male)" =
      nrow(d) == 2L,
    "sex must be 'female' and 'male'" =
      setequal(d$sex, c("female", "male")),
    "required coefficient columns present" =
      all(c("intercept", "b_age", "c_age_sq") %in% names(d)),
    "b_age must be positive (early-career rising hours)" =
      all(d$b_age > 0),
    "c_age_sq must be negative (parabola opening downward)" =
      all(d$c_age_sq < 0),
    "female mathematical peak age must be in [38, 54]" = {
      pa <- peak_age(r_f$b_age, r_f$c_age_sq)
      pa >= 38 && pa <= 54
    },
    "male mathematical peak age must be in [40, 56]" = {
      pa <- peak_age(r_m$b_age, r_m$c_age_sq)
      pa >= 40 && pa <= 56
    },
    "female peak hours must be in [35, 65]" = {
      ph <- peak_hrs(r_f$intercept, r_f$b_age, r_f$c_age_sq)
      ph >= 35 && ph <= 65
    },
    "male peak hours must be in [45, 75]" = {
      ph <- peak_hrs(r_m$intercept, r_m$b_age, r_m$c_age_sq)
      ph >= 45 && ph <= 75
    },
    "male peak hours must exceed female peak hours" =
      peak_hrs(r_m$intercept, r_m$b_age, r_m$c_age_sq) >
        peak_hrs(r_f$intercept, r_f$b_age, r_f$c_age_sq),
    "reference hours must be positive" =
      is.numeric(ref) && length(ref) == 1L && ref > 0,
    "coefficients must reproduce female anchor points (within 0.01 hrs)" = {
      tol <- 0.01
      a <- r_f$intercept
      b <- r_f$b_age
      c <- r_f$c_age_sq
      all(c(
        abs(evaluate(a, b, c, r_f$anchor_age_lo) - r_f$anchor_hours_lo) < tol,
        abs(evaluate(a, b, c, r_f$anchor_age_peak) - r_f$anchor_hours_peak) < tol,
        abs(evaluate(a, b, c, r_f$anchor_age_hi) - r_f$anchor_hours_hi) < tol
      ))
    },
    "coefficients must reproduce male anchor points (within 0.01 hrs)" = {
      tol <- 0.01
      a <- r_m$intercept
      b <- r_m$b_age
      c <- r_m$c_age_sq
      all(c(
        abs(evaluate(a, b, c, r_m$anchor_age_lo) - r_m$anchor_hours_lo) < tol,
        abs(evaluate(a, b, c, r_m$anchor_age_peak) - r_m$anchor_hours_peak) < tol,
        abs(evaluate(a, b, c, r_m$anchor_age_hi) - r_m$anchor_hours_hi) < tol
      ))
    },
    "sex hours version must be semver" =
      grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", .URPS_FTE_SEX_HOURS_VERSION)
  )
})

#' Version of the URPS sex-stratified FTE hours model
#'
#' @description Semantic version of the OLS coefficient set served by this
#'   package. Bump when anchor points, coefficients, or the reference hours
#'   change.
#' @format Length-1 character string (e.g. `"1.0.0"`).
#' @seealso [urps_fte_sex_hours_params()], [urps_fte_weight_sex()]
#' @family URPS FTE sex
#' @examples
#' URPS_FTE_SEX_HOURS_VERSION
#' @export
URPS_FTE_SEX_HOURS_VERSION <- .URPS_FTE_SEX_HOURS_VERSION

#' OLS parameters for the URPS sex-stratified weekly patient care hours model
#'
#' @description The quadratic regression coefficients fit separately for female
#'   and male URPS providers, with the anchor points that define them and their
#'   calibration status. These parameters are the input to
#'   [urps_fte_predicted_hours()] and [urps_fte_weight_sex()].
#'
#' @details **Calibration:** coefficients are fit by quadratic regression to
#'   three anchor points per sex (see `anchor_*` columns) derived from the ACOG
#'   2021 Workforce Survey and AMA 2022 Benchmark Survey for OB/GYN
#'   subspecialists. The `calibration_status` column is `"calibrated_from_literature"`
#'   throughout; ABOG lapse records or a URPS-specific practice survey would
#'   sharpen these estimates.
#'
#'   **Model:** `hours(age) = intercept + b_age * age + c_age_sq * age^2`.
#'
#'   **FTE weight:** `max(hours, 0) / URPS_FTE_REFERENCE_HOURS_PER_WEEK`
#'   (40 hrs/wk = 1.0 FTE).
#'
#' @return A `data.frame` with columns `sex`, `intercept`, `b_age`, `c_age_sq`,
#'   `anchor_age_lo`, `anchor_hours_lo`, `anchor_age_peak`, `anchor_hours_peak`,
#'   `anchor_age_hi`, `anchor_hours_hi`, and `calibration_status`. Carries
#'   attributes `source`, `formula`, and `reference_hours`.
#' @seealso [urps_fte_predicted_hours()], [urps_fte_weight_sex()],
#'   [URPS_FTE_SEX_HOURS_VERSION], [URPS_FTE_REFERENCE_HOURS_PER_WEEK]
#' @family URPS FTE sex
#' @examples
#' urps_fte_sex_hours_params()
#' attr(urps_fte_sex_hours_params(), "source")
#' @export
urps_fte_sex_hours_params <- function() {
  d <- .urps_fte_sex_hours_params_df()
  attr(d, "source") <- paste(
    "ACOG 2021 Workforce Survey (weekly hours by age and sex, OB/GYN subspecialists);",
    "AMA 2022 Physician Practice Benchmark Survey (weekly patient care hours);",
    "IHS Markit HWMM v5.19.20 Exhibits 14-15 (OLS hours-worked model structure).",
    "Sharpen with: ABOG lapse/recertification panel or URPS practice survey."
  )
  attr(d, "formula") <- "hours(age) = intercept + b_age * age + c_age_sq * age^2"
  attr(d, "reference_hours") <- URPS_FTE_REFERENCE_HOURS_PER_WEEK
  d
}

# Internal: validate and index into the params table for a sex vector.
# Vectorized: sex can be length-1 or the same length as age.
.urps_fte_sex_index <- function(sex) {
  if (!is.character(sex) || length(sex) < 1L) {
    stop("[urps_fte_sex] `sex` must be a non-empty character vector.", call. = FALSE)
  }
  d <- .urps_fte_sex_hours_params_df()
  idx <- match(sex, d$sex)
  bad <- unique(sex[is.na(idx)])
  if (length(bad)) {
    stop(sprintf(
      "[urps_fte_sex] unknown sex value(s): %s (must be 'female' or 'male').",
      paste(bad, collapse = ", ")
    ), call. = FALSE)
  }
  idx
}

# Internal: single-sex scalar lookup (used by load-time validator and handoff).
.urps_fte_sex_lookup <- function(sex) {
  if (!is.character(sex) || length(sex) != 1L || !sex %in% c("female", "male")) {
    stop(sprintf(
      "[urps_fte_sex] `sex` must be 'female' or 'male', not '%s'.",
      as.character(sex)[1L]
    ), call. = FALSE)
  }
  d <- .urps_fte_sex_hours_params_df()
  d[d$sex == sex, , drop = FALSE]
}

#' Predicted weekly patient care hours by age and sex
#'
#' @description Evaluates the quadratic OLS model
#'   `hours(age) = intercept + b_age * age + c_age_sq * age^2`.
#'   Vectorized over both `age` and `sex` (recycled against each other, so a
#'   mixed-sex cohort vector works directly). Raw (unclamped) predictions can go
#'   negative at extreme ages; use [urps_fte_weight_sex()] for FTE calculations,
#'   which clamps to zero.
#'
#' @param age Numeric or integer vector of ages. Must be non-empty.
#' @param sex Character vector of `"female"` / `"male"` values, recycled against
#'   `age`. Can be length-1 (applied to all ages) or the same length as `age`
#'   (one sex per provider row).
#' @return Numeric vector the same length as `max(length(age), length(sex))`
#'   (weekly hours; may be negative at extreme ages).
#' @seealso [urps_fte_weight_sex()], [urps_fte_sex_hours_params()]
#' @family URPS FTE sex
#' @examples
#' urps_fte_predicted_hours(35:75, "female")
#' urps_fte_predicted_hours(47, "male") # peak: ~55 hrs/week
#' # mixed-sex cohort vector:
#' urps_fte_predicted_hours(c(45, 55), c("female", "male"))
#' @export
urps_fte_predicted_hours <- function(age, sex) {
  if (!(is.numeric(age) || is.integer(age)) || length(age) < 1L) {
    stop("[urps_fte_predicted_hours] `age` must be a non-empty numeric or integer vector.",
      call. = FALSE
    )
  }
  d <- .urps_fte_sex_hours_params_df()
  idx <- .urps_fte_sex_index(sex)
  a <- as.numeric(age)
  d$intercept[idx] + d$b_age[idx] * a + d$c_age_sq[idx] * a^2
}

#' Per-provider URPS FTE weight (sex-stratified hours model)
#'
#' @description Sex-stratified upgrade to [urps_fte_weight()], following the
#'   IHS Markit HWMM Exhibits 14-15 OLS hours-worked approach. The weight is:
#'
#'   `max(predicted_hours(age, sex), 0) / 40`
#'   `* URPS_FTE_PATHWAY_CLINICAL_TIME[pathway]`
#'   `* late_career_factor`
#'
#'   40 hrs/week = 1.0 FTE ([URPS_FTE_REFERENCE_HOURS_PER_WEEK]). A
#'   subspecialist at career peak works > 1.0 FTE; a late-career provider with
#'   reduced hours may be < 1.0 FTE.
#'
#' @details Use this function when cliff's provider cohort carries per-provider
#'   (or per-cell) sex data. Use [urps_fte_weight()] when sex data are
#'   unavailable, as that function does not require sex.
#'
#'   The `pathway_clinical_time` factor ([URPS_FTE_PATHWAY_CLINICAL_TIME]) is
#'   applied after the hours-to-FTE conversion, capturing the specialty-time
#'   split (ABOG = 1.0 full URPS time; ABU = 0.7 mixed urology/GYN) independently
#'   of the age-sex productivity model.
#'
#' @param age Numeric or integer vector of ages.
#' @param sex `"female"` or `"male"` (length-1, recycled against `age`).
#' @param pathway `"ABOG"` or `"ABU"` (recycled against `age`).
#' @param late_from_age If non-`NULL`, ages at or above this receive
#'   `late_factor` (pass `urps_scenario(id)$late_career_fte_onset_age`).
#' @param late_factor Late-career FTE multiplier (pass
#'   `urps_scenario(id)$late_career_fte_factor`; default `1` = no reduction).
#' @return Numeric weight(s) the same length as `age`. Values > 1 indicate
#'   above-reference hours; values in (0, 1) indicate below-reference hours or
#'   reduced specialty time.
#' @seealso [urps_fte_predicted_hours()], [urps_fte_weight()],
#'   [URPS_FTE_PATHWAY_CLINICAL_TIME], [URPS_FTE_REFERENCE_HOURS_PER_WEEK],
#'   [urps_scenarios()]
#' @family URPS FTE sex
#' @examples
#' # Peak male ABOG: ~55 hrs / 40 * 1.0 = 1.375 FTE
#' urps_fte_weight_sex(47, "male", "ABOG")
#' # Peak female ABU: ~47 hrs / 40 * 0.7 = 0.823 FTE
#' urps_fte_weight_sex(45, "female", "ABU")
#' # Late-career scenario from the registry:
#' sc <- urps_scenario("lower_late_career_fte")
#' urps_fte_weight_sex(62, "female", "ABOG",
#'   late_from_age = sc$late_career_fte_onset_age,
#'   late_factor   = sc$late_career_fte_factor
#' )
#' @export
urps_fte_weight_sex <- function(age, sex, pathway = "ABOG",
                                late_from_age = NULL, late_factor = 1) {
  if (!(is.numeric(age) || is.integer(age)) || length(age) < 1L) {
    stop("[urps_fte_weight_sex] `age` must be a non-empty numeric or integer vector.",
      call. = FALSE
    )
  }
  if (!is.character(pathway) || !all(pathway %in% c("ABOG", "ABU"))) {
    stop(
      sprintf(
        "[urps_fte_weight_sex] `pathway` must be 'ABOG' or 'ABU', not '%s'.",
        paste(unique(pathway[!pathway %in% c("ABOG", "ABU")]), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  hrs <- pmax(urps_fte_predicted_hours(age, sex), 0)
  ct <- unname(URPS_FTE_PATHWAY_CLINICAL_TIME[pathway])
  ct[is.na(ct)] <- 1.0
  late <- if (!is.null(late_from_age)) {
    ifelse(as.numeric(age) >= late_from_age, late_factor, 1)
  } else {
    1
  }

  (hrs / URPS_FTE_REFERENCE_HOURS_PER_WEEK) * ct * late
}

#' Effective clinical FTE of a sex-stratified headcount cohort
#'
#' @description Sex-aware counterpart to [urps_effective_fte()]: computes
#'   `scale * sum(n * urps_fte_weight_sex(age, sex, pathway, ...))` for a
#'   cohort data.frame that carries per-row sex. Use [urps_fte_scale_sex()] to
#'   anchor the reference cohort's FTE to its headcount before comparing across
#'   years or geographies.
#'
#' @param counts A `data.frame` with columns `age`, `sex`, `pathway`, and `n`.
#'   Mixed-sex rows are handled natively (no pre-splitting required).
#' @param scale Normalization scale from [urps_fte_scale_sex()] (default `1` =
#'   raw hours/40 weighted sum).
#' @param late_from_age,late_factor Passed to [urps_fte_weight_sex()].
#' @return A length-1 numeric (clinical FTE in 40-hrs/wk units after scaling).
#' @seealso [urps_fte_scale_sex()], [urps_fte_weight_sex()], [urps_effective_fte()]
#' @family URPS FTE sex
#' @examples
#' cs <- data.frame(
#'   age     = c(45L, 62L, 45L, 62L),
#'   sex     = c("female", "female", "male", "male"),
#'   pathway = c("ABOG", "ABOG", "ABU", "ABU"),
#'   n       = c(350, 150, 100, 40)
#' )
#' urps_effective_fte_sex(cs, scale = urps_fte_scale_sex(cs))
#' @export
urps_effective_fte_sex <- function(counts, scale = 1,
                                   late_from_age = NULL, late_factor = 1) {
  need <- c("age", "sex", "pathway", "n")
  miss <- setdiff(need, names(counts))
  if (length(miss)) {
    stop(sprintf(
      "[urps_effective_fte_sex] missing required column(s): %s.",
      paste(miss, collapse = ", ")
    ), call. = FALSE)
  }
  w <- urps_fte_weight_sex(
    counts$age, counts$sex, counts$pathway,
    late_from_age, late_factor
  )
  as.numeric(scale) * sum(counts$n * w)
}

#' Normalization scale anchoring a sex-stratified reference cohort's FTE to a target
#'
#' @description Sex-aware counterpart to [urps_fte_scale()]: computes the scale
#'   factor so that `urps_effective_fte_sex(reference_counts, scale)` equals
#'   `target_headcount`. Apply once to the 2023 baseline cohort; reuse the same
#'   scale for all projection years so FTE is comparable across time.
#'
#' @param reference_counts A `data.frame(age, sex, pathway, n)` — typically the
#'   2023 baseline active cohort with sex distribution applied.
#' @param target_headcount The headcount the reference cohort's FTE should equal
#'   (default `sum(reference_counts$n)`, i.e. FTE(reference) == headcount).
#' @return A length-1 numeric scale for [urps_effective_fte_sex()].
#' @seealso [urps_effective_fte_sex()], [urps_fte_scale()]
#' @family URPS FTE sex
#' @examples
#' cs <- data.frame(
#'   age     = c(45L, 62L, 45L, 62L),
#'   sex     = c("female", "female", "male", "male"),
#'   pathway = c("ABOG", "ABOG", "ABU", "ABU"),
#'   n       = c(350, 150, 100, 40)
#' )
#' urps_fte_scale_sex(cs)
#' @export
urps_fte_scale_sex <- function(reference_counts,
                               target_headcount = sum(reference_counts$n)) {
  raw <- urps_effective_fte_sex(reference_counts, scale = 1)
  if (!is.finite(raw) || raw <= 0) {
    stop("[urps_fte_scale_sex] reference cohort has non-positive weighted FTE.",
      call. = FALSE
    )
  }
  as.numeric(target_headcount) / raw
}

#' Full supply pipeline: certified headcount -> supply_clinical_fte (sex-stratified)
#'
#' @description Composes the three supply-side adjustments in the correct order:
#'
#'   1. **LFP** (`urps_p_active`): `certified_n → practicing_n`
#'   2. **FTE weight** (`urps_fte_weight_sex`): hours/40 × pathway clinical time × late_factor
#'   3. **Scale** (`baseline_scale`): anchors FTE to the 2023 baseline headcount
#'
#'   Equivalent to:
#'   ```r
#'   cohort <- urps_apply_lfp(cohort)   # adds practicing_n
#'   urps_effective_fte_sex(
#'     data.frame(age=cohort$age, sex=cohort$sex,
#'                pathway=cohort$pathway, n=cohort$practicing_n),
#'     scale = baseline_scale, ...)
#'   ```
#'   Use this function when cliff passes certified headcount per cohort cell.
#'   If practicing headcount is already known (e.g. from survey direct-count),
#'   call [urps_effective_fte_sex()] directly.
#'
#' @param cohort A `data.frame` with columns `age`, `sex`, `pathway`, and
#'   `certified_n`. The `n` column (if present) is ignored; `certified_n` is used.
#' @param baseline_scale Scale from [urps_fte_scale_sex()] computed on the 2023
#'   baseline certified cohort. Must be computed ONCE and reused across years.
#' @param late_from_age,late_factor Late-career FTE lever — pass values from
#'   `urps_scenario(id)$late_career_fte_onset_age` and
#'   `urps_scenario(id)$late_career_fte_factor`. Defaults leave weight unchanged.
#' @return Length-1 numeric: `supply_clinical_fte` for this cohort row.
#' @seealso [urps_apply_lfp()], [urps_effective_fte_sex()], [urps_fte_scale_sex()],
#'   [urps_p_active()], [urps_fte_weight_sex()]
#' @family URPS FTE sex
#' @examples
#' cohort <- data.frame(
#'   age = c(45L, 62L, 45L, 62L),
#'   sex = c("female", "female", "male", "male"),
#'   pathway = c("ABOG", "ABOG", "ABU", "ABU"),
#'   certified_n = c(350, 150, 100, 40)
#' )
#' scale <- urps_fte_scale_sex(
#'   cbind(cohort, n = cohort$certified_n *
#'     urps_p_active(cohort$age, cohort$sex))
#' )
#' urps_supply_fte_sex(cohort, scale)
#' @export
urps_supply_fte_sex <- function(cohort, baseline_scale,
                                late_from_age = NULL, late_factor = 1) {
  need <- c("age", "sex", "pathway", "certified_n")
  miss <- setdiff(need, names(cohort))
  if (length(miss)) {
    stop(sprintf(
      "[urps_supply_fte_sex] missing required column(s): %s.",
      paste(miss, collapse = ", ")
    ), call. = FALSE)
  }
  practicing <- urps_apply_lfp(cohort)
  urps_effective_fte_sex(
    data.frame(
      age = practicing$age,
      sex = practicing$sex,
      pathway = practicing$pathway,
      n = practicing$practicing_n,
      stringsAsFactors = FALSE
    ),
    scale = baseline_scale,
    late_from_age = late_from_age,
    late_factor = late_factor
  )
}
