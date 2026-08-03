# ==============================================================================
# URPS specialty × setting calibration scalar skeleton.
#
# The IHS Markit HWMM (v5.19.20) calibrates regression-predicted visit totals
# against NAMCS / NHAMCS / NIS national counts using multiplicative scalars,
# one per specialty × setting combination. The scalar absorbs the gap between
# what the MEPS-fitted regression predicts in aggregate and what the national
# survey total observes for that specialty and setting.
#
# Formula (per specialty s, setting t, patient i):
#   predicted_visits(i, s, t) = scalar(s, t) * exp(Xb(i, s, t))
#
# CURRENT STATUS: calibration_status = "not_calibrated"
#   All scalars are 1.0 (identity = no calibration applied). They populate
#   when NAMCS/NHAMCS/NIS national totals for URPS services are available.
#
# Settings:
#   office      — office-based physician visits (NAMCS)
#   outpatient  — hospital outpatient department visits (NHAMCS-OPD)
#   home_health — home health visits (MEPS home health module)
#   inpatient   — hospitalizations (NIS)
#   ed          — emergency department visits (NHAMCS-ED)
#
# Calibration data acquisition path:
#   NAMCS: CDC restricted-use, filtered to URPS specialty codes
#   NHAMCS: CDC restricted-use, OPD and ED modules
#   NIS:   AHRQ Healthcare Cost and Utilization Project
# ==============================================================================

.URPS_DEMAND_SCALARS_VERSION <- "0.2.0"  # pre-calibration; bump to 1.0.0 on first fit

.urps_demand_scalars_df <- function() {
  data.frame(
    specialty            = "URPS",
    setting              = c("office", "outpatient", "home_health", "inpatient", "ed",
                             "retail_clinic"),
    scalar               = c(1.0,      1.0,          1.0,          1.0,         1.0,
                             1.0),
    calibration_source   = c(
      "NAMCS",          # office
      "NHAMCS_OPD",     # outpatient
      "MEPS_home",      # home_health
      "NIS",            # inpatient
      "NHAMCS_ED",      # ed
      "NAMCS_retail"    # retail_clinic — retail health clinic visits (NAMCS supplement)
    ),
    calibration_status   = "not_calibrated",
    stringsAsFactors     = FALSE
  )
}

local({
  d <- .urps_demand_scalars_df()
  expected_settings <- c("office", "outpatient", "home_health", "inpatient", "ed",
                         "retail_clinic")
  stopifnot(
    "demand scalars must have exactly 6 rows" =
      nrow(d) == 6L,
    "setting must be unique" =
      !anyDuplicated(d$setting),
    "settings must be the expected set" =
      setequal(d$setting, expected_settings),
    "specialty must be 'URPS'" =
      all(d$specialty == "URPS"),
    "scalars must be positive" =
      all(d$scalar > 0),
    "calibration_status must be 'not_calibrated' (skeleton)" =
      all(d$calibration_status == "not_calibrated"),
    "calibration_source must be non-empty" =
      all(nzchar(d$calibration_source)),
    "demand scalars version must be semver" =
      grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", .URPS_DEMAND_SCALARS_VERSION)
  )
})

#' Version of the URPS demand calibration scalar skeleton
#'
#' @description Pre-calibration version `"0.1.0"` — all scalars are `1.0`.
#'   Bump to `"1.0.0"` when NAMCS/NHAMCS/NIS totals are fitted.
#' @format Length-1 character string.
#' @seealso [urps_demand_scalars()], [urps_demand_params()]
#' @family URPS demand
#' @examples
#' URPS_DEMAND_SCALARS_VERSION
#' @export
URPS_DEMAND_SCALARS_VERSION <- .URPS_DEMAND_SCALARS_VERSION

#' URPS specialty × setting calibration scalar table (skeleton)
#'
#' @description Multiplicative scalars aligning MEPS-fitted visit predictions to
#'   NAMCS/NHAMCS/NIS national survey totals, one per service setting. All
#'   scalars are `1.0` until calibrated.
#'
#'   **How scalars compose with the regression:**
#'   ```
#'   predicted_visits(i, setting) =
#'     scalar(setting) * exp(intercept + b_age*age + ... + b_urban*urban)
#'   ```
#'   The scalar is the ratio of the NAMCS/NHAMCS/NIS observed national total to
#'   the aggregate MEPS-predicted total, holding the covariate distribution fixed.
#'
#' @return A `data.frame` with columns `specialty`, `setting`, `scalar`,
#'   `calibration_source`, and `calibration_status`. Carries attributes `source`
#'   and `formula_note`.
#' @seealso [urps_demand_params()], [urps_demand_clinical_fte()],
#'   [URPS_DEMAND_SCALARS_VERSION]
#' @family URPS demand
#' @examples
#' urps_demand_scalars()
#' urps_demand_scalars()[, c("setting", "scalar", "calibration_status")]
#' @export
urps_demand_scalars <- function() {
  d <- .urps_demand_scalars_df()
  attr(d, "source") <- paste(
    "IHS Markit HWMM v5.19.20 (calibration approach, specialty x setting structure);",
    "NAMCS — National Ambulatory Medical Care Survey (office visits);",
    "NHAMCS-OPD — outpatient department visits;",
    "NHAMCS-ED  — emergency department visits;",
    "NIS        — AHRQ National Inpatient Sample (hospitalizations);",
    "MEPS home health module (home health visits).",
    "URPS-specific scalars pending NAMCS/NIS data acquisition.")
  attr(d, "formula_note") <-
    "scalar(setting) = NAMCS/NIS_total(setting) / sum_i(exp(Xb_i))"
  d
}

#' Look up the calibration scalar for a service setting
#'
#' @description Returns the multiplicative calibration scalar for one setting.
#'   Until calibrated, this is always `1.0`. Fail-loud on unknown settings.
#'
#' @param setting One of `"office"`, `"outpatient"`, `"home_health"`,
#'   `"inpatient"`, `"ed"`.
#' @return Length-1 numeric scalar (positive).
#' @seealso [urps_demand_scalars()]
#' @family URPS demand
#' @examples
#' urps_demand_scalar("office")     # 1.0 until calibrated
#' urps_demand_scalar("inpatient")
#' @export
urps_demand_scalar <- function(setting) {
  d <- .urps_demand_scalars_df()
  if (!is.character(setting) || length(setting) != 1L || is.na(setting))
    stop("[urps_demand_scalar] `setting` must be a single string.", call. = FALSE)
  i <- match(setting, d$setting)
  if (is.na(i))
    stop(sprintf("[urps_demand_scalar] unknown setting '%s'; must be one of: %s.",
                 setting, paste(d$setting, collapse = ", ")), call. = FALSE)
  d$scalar[i]
}
