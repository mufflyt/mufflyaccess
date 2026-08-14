# ==============================================================================
# URPS retirement survival curve model.
#
# mufflyaccess owns the DEFINITION of the logistic survival curve: the parameter
# table (mu, sigma by sex x pathway) and the functions that evaluate it.
# cliff owns the APPLICATION: applying urps_retirement_hazard() per-cohort in
# the annual projection recurrence to compute exits.
#
# Model: logistic survival function
#   S(age; mu, sigma) = 1 / (1 + exp((age - mu) / sigma))
#   mu    = median retirement age (50% still active at this age)
#   sigma = spread (years; smaller = sharper retirement cliff)
#
# Parameters are sex x certification_pathway specific (4 combinations).
# The scenario retirement_shift_years lever shifts the effective age:
#   effective_age = age - retirement_shift_years
# so shift = -2 (retire earlier) makes the curve behave as if each provider
# is 2 years older, producing lower survival (more exits). shift = +2 raises
# survival (fewer exits).
#
# Calibration status: "calibrated_from_literature" -- parameters are informed
# by published physician retirement patterns but are NOT estimated from ABOG
# lapse/recertification records. The calibration_status column makes this
# explicit so every consumer and reviewer knows these are placeholder-quality
# pending a URPS-specific data source (ABOG certification panel or ACOG
# workforce survey).
#
# Sources used for calibration:
#   IHS Markit HWMM v5.19.20, Exhibit 17 (physician retirement by age and sex)
#   AAMC 2022 Physician Workforce Report, Table 1.3
#   ACOG 2021 Workforce Survey (retirement age distributions by sex)
#   AMA 2022 Physician Practice Benchmark Survey
# ==============================================================================

.URPS_RETIREMENT_CURVE_VERSION <- "1.0.0"

# Internal: the single source of parameter values.
# Called by the load-time validator AND by urps_retirement_params(), so numbers
# are never defined twice. sex values: lowercase "female"/"male". pathway values:
# "ABOG"/"ABU" (per-individual pathway, NOT the three-value count-contract vocab).
.urps_retirement_params_df <- function() {
  data.frame(
    sex                  = c("female", "male", "female", "male"),
    certification_pathway = c("ABOG",   "ABOG",  "ABU",    "ABU"),
    mu_years             = c(65.0,      68.0,    64.0,     67.0),
    sigma_years          = c(4.0,       4.0,     4.0,      4.0),
    calibration_status   = "calibrated_from_literature",
    stringsAsFactors     = FALSE
  )
}

# Load-time validation: fail loud on any impossible edit to the parameter table.
local({
  d <- .urps_retirement_params_df()
  stopifnot(
    "retirement params must have required columns" =
      all(c("sex", "certification_pathway", "mu_years",
            "sigma_years", "calibration_status") %in% names(d)),
    "retirement params must have exactly 4 rows (female/male x ABOG/ABU)" =
      nrow(d) == 4L,
    "sex must be 'female' or 'male' only" =
      all(d$sex %in% c("female", "male")),
    "certification_pathway must be 'ABOG' or 'ABU' only" =
      all(d$certification_pathway %in% c("ABOG", "ABU")),
    "sex x pathway combinations must be unique" =
      !anyDuplicated(paste(d$sex, d$certification_pathway, sep = "/")),
    "all four sex x pathway combinations must be present" =
      setequal(paste(d$sex, d$certification_pathway, sep = "/"),
               c("female/ABOG", "male/ABOG", "female/ABU", "male/ABU")),
    "mu_years must be in [50, 80] (plausible physician retirement age range)" =
      all(is.finite(d$mu_years)) && all(d$mu_years >= 50) && all(d$mu_years <= 80),
    "sigma_years must be in [1, 15] (plausible retirement spread)" =
      all(is.finite(d$sigma_years)) &&
      all(d$sigma_years >= 1) && all(d$sigma_years <= 15),
    "female mu must be less than male mu for ABOG (female physicians retire earlier)" =
      d$mu_years[d$sex == "female" & d$certification_pathway == "ABOG"] <
      d$mu_years[d$sex == "male"   & d$certification_pathway == "ABOG"],
    "female mu must be less than male mu for ABU (female physicians retire earlier)" =
      d$mu_years[d$sex == "female" & d$certification_pathway == "ABU"] <
      d$mu_years[d$sex == "male"   & d$certification_pathway == "ABU"],
    "calibration_status must be a known value" =
      all(d$calibration_status %in% "calibrated_from_literature"),
    "curve version must be semver" =
      grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", .URPS_RETIREMENT_CURVE_VERSION)
  )
})

#' Version of the URPS retirement survival curve model
#'
#' @description Semantic version of the logistic survival curve parameter set
#'   served by this package. Bump when parameters or the formula change, so a
#'   downstream projection can record exactly which curve it was built against.
#' @format Length-1 character string (e.g. `"1.0.0"`).
#' @seealso [urps_retirement_params()], [urps_p_still_active()]
#' @family URPS retirement curve
#' @examples
#' URPS_RETIREMENT_CURVE_VERSION
#' @export
URPS_RETIREMENT_CURVE_VERSION <- .URPS_RETIREMENT_CURVE_VERSION

#' Literature-calibrated URPS retirement survival curve parameters
#'
#' @description The logistic survival curve parameter table (mu, sigma) for the
#'   URPS retirement model, stratified by sex and certification pathway. These are
#'   the inputs to [urps_p_still_active()] and [urps_retirement_hazard()].
#'
#' @details **Calibration status:** `"calibrated_from_literature"` — parameters
#'   are derived from published physician retirement patterns (see the `source`
#'   attribute) but are NOT estimated from ABOG-specific lapse or
#'   recertification data. This status is intentionally explicit so consumers
#'   and reviewers know these are placeholder-quality pending a URPS-specific
#'   data source (ABOG certification panel or an ACOG workforce survey).
#'
#'   **Pathway vocabulary:** `certification_pathway` here is `"ABOG"` or
#'   `"ABU"` — the per-individual pathway, NOT the three-value count-contract
#'   vocabulary (`"ABOG"` / `"ABU_NET_NEW"` / `"ABOG_PLUS_ABU"`). The
#'   retirement hazard applies to individual providers, not to aggregated
#'   pathway cells.
#'
#' @return A `data.frame` with columns `sex` (`"female"` or `"male"`),
#'   `certification_pathway` (`"ABOG"` or `"ABU"`), `mu_years` (median
#'   retirement age), `sigma_years` (spread), and `calibration_status`.
#'   Carries attributes `source`, `formula`, and `curve_type`.
#' @seealso [urps_p_still_active()], [urps_retirement_hazard()],
#'   [urps_survival_curve()], [URPS_RETIREMENT_CURVE_VERSION]
#' @family URPS retirement curve
#' @examples
#' urps_retirement_params()
#' attr(urps_retirement_params(), "source")
#' attr(urps_retirement_params(), "formula")
#' @export
urps_retirement_params <- function() {
  d <- .urps_retirement_params_df()
  attr(d, "source") <- paste(
    "IHS Markit HWMM v5.19.20 Exhibit 17 (physician retirement by age and sex);",
    "AAMC 2022 Physician Workforce Report Table 1.3;",
    "ACOG 2021 Workforce Survey (retirement age by sex);",
    "AMA 2022 Physician Practice Benchmark Survey.",
    "Sharpen with: ABOG lapse/recertification panel or URPS practice survey.")
  attr(d, "formula")    <- "S(age; mu, sigma) = 1 / (1 + exp((age - mu) / sigma))"
  attr(d, "curve_type") <- "logistic_survival"
  d
}

# Internal: logistic survival kernel. Vectorized over age; mu and sigma are
# scalars looked up from the params table. Matches the formula in
# attr(urps_retirement_params(), "formula") exactly.
.urps_logistic_s <- function(age, mu, sigma) {
  1.0 / (1.0 + exp((as.numeric(age) - mu) / sigma))
}

# Internal: look up mu and sigma for a single sex x pathway combination.
# Fails loud on unknown values with the [function] prefix convention.
.urps_retirement_lookup <- function(sex, pathway) {
  if (!is.character(sex) || length(sex) != 1L || !sex %in% c("female", "male"))
    stop(sprintf(
      "[urps_retirement] `sex` must be 'female' or 'male', not '%s'.",
      as.character(sex)[1L]), call. = FALSE)
  if (!is.character(pathway) || length(pathway) != 1L ||
      !pathway %in% c("ABOG", "ABU"))
    stop(sprintf(
      "[urps_retirement] `pathway` must be 'ABOG' or 'ABU', not '%s'.",
      as.character(pathway)[1L]), call. = FALSE)
  d   <- .urps_retirement_params_df()
  row <- d[d$sex == sex & d$certification_pathway == pathway, , drop = FALSE]
  list(mu = row$mu_years, sigma = row$sigma_years)
}

#' P(still active) at a given age under the URPS logistic retirement model
#'
#' @description The logistic survival function
#'   `S(age; mu, sigma) = 1 / (1 + exp((age - mu) / sigma))`,
#'   evaluated at the effective age after applying the scenario retirement shift.
#'   Vectorized over `age`; `sex` and `pathway` must be length-1 scalars (call
#'   once per sex x pathway cell of your projection cohort).
#'
#' @details **Scenario shift:** `effective_age = age - retirement_shift_years`.
#'   Pass `urps_scenario(id)$retirement_shift_years` directly.
#'   - `retirement_shift_years = -2` (retire earlier): `effective_age = age + 2`,
#'     so the curve shifts left — lower survival — more exits. ✓
#'   - `retirement_shift_years = +2` (retire later): `effective_age = age - 2`,
#'     higher survival — fewer exits. ✓
#'
#' @param age Numeric or integer vector of ages to evaluate. Must be non-empty.
#' @param sex `"female"` or `"male"` (length-1).
#' @param pathway `"ABOG"` or `"ABU"` (per-individual pathway; length-1).
#' @param retirement_shift_years Finite numeric scalar from the scenario
#'   registry (`urps_scenario(id)$retirement_shift_years`; default `0L`).
#' @return Numeric vector the same length as `age`, values in (0, 1).
#' @seealso [urps_retirement_hazard()], [urps_survival_curve()],
#'   [urps_retirement_params()], [urps_scenarios()]
#' @family URPS retirement curve
#' @examples
#' # at mu (65), female ABOG survival is exactly 0.5
#' urps_p_still_active(65, "female", "ABOG")
#' # full age range, no scenario shift
#' urps_p_still_active(35:80, "male", "ABU")
#' # retire-2-years-earlier scenario
#' urps_p_still_active(65, "female", "ABOG",
#'   retirement_shift_years = urps_scenario("retire_2yr_earlier")$retirement_shift_years)
#' @export
urps_p_still_active <- function(age, sex, pathway, retirement_shift_years = 0L) {
  if (!(is.numeric(age) || is.integer(age)) || length(age) < 1L)
    stop("[urps_p_still_active] `age` must be a non-empty numeric or integer vector.",
         call. = FALSE)
  if (!(is.numeric(retirement_shift_years) || is.integer(retirement_shift_years)) ||
      length(retirement_shift_years) != 1L || !is.finite(retirement_shift_years))
    stop("[urps_p_still_active] `retirement_shift_years` must be a single finite scalar.",
         call. = FALSE)
  p            <- .urps_retirement_lookup(sex, pathway)
  effective_age <- as.numeric(age) - as.numeric(retirement_shift_years)
  .urps_logistic_s(effective_age, p$mu, p$sigma)
}

#' Annual retirement hazard: P(retire at age | active at age - 1)
#'
#' @description The discrete conditional retirement probability at each integer
#'   age, defined as `(S(age-1) - S(age)) / S(age-1)`, clamped to `[0, 1]`.
#'   This is the quantity cliff applies per-cohort in the yearly recurrence:
#'   `exits[age] = cohort_n[age-1] * urps_retirement_hazard(age, sex, pathway, shift)`.
#'   Vectorized over `age`.
#'
#' @inheritParams urps_p_still_active
#' @return Numeric vector the same length as `age`, values in `[0, 1]`.
#' @seealso [urps_p_still_active()], [urps_survival_curve()]
#' @family URPS retirement curve
#' @examples
#' urps_retirement_hazard(55:75, "female", "ABOG")
#' urps_retirement_hazard(68, "male", "ABOG",
#'   retirement_shift_years = urps_scenario("retire_2yr_later")$retirement_shift_years)
#' @export
urps_retirement_hazard <- function(age, sex, pathway, retirement_shift_years = 0L) {
  if (!(is.numeric(age) || is.integer(age)) || length(age) < 1L)
    stop("[urps_retirement_hazard] `age` must be a non-empty numeric or integer vector.",
         call. = FALSE)
  if (!(is.numeric(retirement_shift_years) || is.integer(retirement_shift_years)) ||
      length(retirement_shift_years) != 1L || !is.finite(retirement_shift_years))
    stop("[urps_retirement_hazard] `retirement_shift_years` must be a single finite scalar.",
         call. = FALSE)
  s_prev <- urps_p_still_active(as.numeric(age) - 1, sex, pathway, retirement_shift_years)
  s_curr <- urps_p_still_active(as.numeric(age),     sex, pathway, retirement_shift_years)
  h <- (s_prev - s_curr) / s_prev
  # Clamp to [0, 1]: S is monotone decreasing so h >= 0 almost always, but
  # floating-point arithmetic at extreme ages (s_prev ~ 1 or ~ 0) can produce
  # trivially out-of-range values. The clamp is defensive, not conceptual.
  pmin(pmax(h, 0), 1)
}

#' Full URPS retirement survival curve as a data.frame
#'
#' @description Returns the complete logistic survival curve and annual hazard
#'   over a specified age range as a `data.frame`. Convenience wrapper for cliff
#'   to tabulate or plot the retirement curve for one sex x pathway x scenario
#'   combination.
#'
#' @param sex `"female"` or `"male"` (length-1).
#' @param pathway `"ABOG"` or `"ABU"` (length-1).
#' @param retirement_shift_years Finite numeric scalar scenario lever (default
#'   `0L`). Pass `urps_scenario(id)$retirement_shift_years`.
#' @param age_range Integer or numeric vector of ages (default `35:80`).
#' @return A `data.frame` with columns `age` (integer), `p_still_active`
#'   (numeric, in (0, 1)), and `annual_hazard` (numeric, in `[0, 1]`). One row
#'   per element of `age_range`.
#' @seealso [urps_p_still_active()], [urps_retirement_hazard()],
#'   [urps_retirement_params()]
#' @family URPS retirement curve
#' @examples
#' head(urps_survival_curve("female", "ABOG"))
#' # retire-2-years-earlier scenario, focused age range:
#' urps_survival_curve("male", "ABOG",
#'   retirement_shift_years = urps_scenario("retire_2yr_earlier")$retirement_shift_years,
#'   age_range = 55:75)
#' @export
urps_survival_curve <- function(sex, pathway,
                                retirement_shift_years = 0L,
                                age_range = 35:80) {
  if (!(is.numeric(age_range) || is.integer(age_range)) || length(age_range) < 1L)
    stop("[urps_survival_curve] `age_range` must be a non-empty numeric or integer vector.",
         call. = FALSE)
  data.frame(
    age            = as.integer(age_range),
    p_still_active = urps_p_still_active(age_range, sex, pathway, retirement_shift_years),
    annual_hazard  = urps_retirement_hazard(age_range, sex, pathway, retirement_shift_years),
    stringsAsFactors = FALSE
  )
}
