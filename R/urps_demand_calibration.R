# ==============================================================================
# URPS demand-model calibration: the ingestion contract.
#
# R/urps_demand.R ships the NA skeleton (urps_demand_params(),
# calibration_status = "not_calibrated"). This file is the OTHER half of the
# calibration loop: the fail-loud contract a *fitted* parameter artifact must
# satisfy, and the reader that ingests one. The fitting pipeline that PRODUCES
# such an artifact from MEPS / NAMCS survey data lives in
# analysis/urps_demand/fit_urps_demand.R; it runs wherever the restricted data
# and the `survey` package are available, and writes a CSV that
# read_urps_demand_params() validates and serves.
#
# The whole point is that the moment a real fit exists, activation is trivial:
#   options(mufflyaccess.urps_demand_params_path = "<fitted>.csv")
# and urps_demand_params() can delegate to read_urps_demand_params() (a small,
# documented hook in urps_demand.R) -- at which point urps_demand_fte() and
# urps_gap_fte() light up across cliff and twostep with no consumer change.
#
# This module is base R only (no survey / no MEPS needed) so the CONTRACT is
# validated and tested here, independent of the data that fills it.
# ==============================================================================

.URPS_DEMAND_SERVICE_TYPES <- c(
  "office_visit", "outpatient_visit", "home_health_visit",
  "hospitalization_prob", "ed_visit_prob", "hospital_los"
)

.URPS_DEMAND_MODEL_FORMS <- c(
  office_visit         = "negative_binomial",
  outpatient_visit     = "negative_binomial",
  home_health_visit    = "negative_binomial",
  hospitalization_prob = "logistic",
  ed_visit_prob        = "logistic",
  hospital_los         = "poisson"
)

# The regression coefficient columns every service row must carry (intercept +
# the b_* covariates), matching the skeleton in urps_demand_params().
.URPS_DEMAND_BETA_COLS <- c(
  "intercept", "b_age", "b_sex_male",
  "b_race_black", "b_race_hispanic", "b_race_other",
  "b_bmi", "b_smoking_current",
  "b_income_low", "b_income_mid",
  "b_insurance_medicaid", "b_insurance_medicare", "b_insurance_uninsured",
  "b_managed_care", "b_chronic_count", "b_urban"
)

.URPS_DEMAND_CALIBRATION_STATES <- c(
  "not_calibrated", # skeleton: every beta NA
  "calibrated", # a real survey fit (MEPS/NAMCS)
  "literature_proxy", # provisional betas from published rates (clearly flagged)
  "example"
) # a synthetic, typed example of the format

#' Schema of a URPS demand-model parameter artifact
#'
#' @description The column contract a fitted (or example) demand-parameter table
#'   must satisfy to be ingested by [read_urps_demand_params()]. It mirrors the
#'   structure `urps_demand_params()` returns, so a validated artifact is a
#'   drop-in for the NA skeleton once real coefficients exist.
#' @return A `data.frame` with one row per column: `column`, `type`, `required`,
#'   and `description`.
#' @seealso [validate_urps_demand_params()], [read_urps_demand_params()],
#'   [urps_demand_params()]
#' @family URPS demand
#' @examples
#' urps_demand_params_schema()
#' @export
urps_demand_params_schema <- function() {
  betas <- data.frame(
    column = .URPS_DEMAND_BETA_COLS,
    type = "double",
    required = TRUE,
    description = "Regression coefficient (NA only when calibration_status = 'not_calibrated').",
    stringsAsFactors = FALSE
  )
  rbind(
    data.frame(
      column = c("service_type", "model_form", "outcome_units"),
      type = "character",
      required = TRUE,
      description = c(
        "One of the six URPS service types (unique key).",
        "negative_binomial / logistic / poisson (fixed per service_type).",
        "Outcome unit label (annual_visit_count / probability_0_1 / days_per_admission)."
      ),
      stringsAsFactors = FALSE
    ),
    betas,
    data.frame(
      column = c("nb_theta", "calibration_scalar", "data_source", "calibration_status"),
      type = c("double", "double", "character", "character"),
      required = TRUE,
      description = c(
        "Negative-binomial dispersion; non-NA (>0) for NB rows when calibrated, NA otherwise.",
        "Specialty x setting calibration scalar (> 0); see urps_demand_scalars().",
        "Fitting data source (e.g. 'MEPS_2013_2017').",
        paste("One of:", paste(.URPS_DEMAND_CALIBRATION_STATES, collapse = ", "), ".")
      ),
      stringsAsFactors = FALSE
    )
  )
}

#' Validate a URPS demand-model parameter artifact
#'
#' @description Fail-loud check that a demand-parameter `data.frame` conforms to
#'   [urps_demand_params_schema()] and is internally consistent with its declared
#'   `calibration_status`: the six service types and their model forms are exactly
#'   as specified; every required column is present; `calibration_scalar > 0`; and
#'   the coefficient/dispersion pattern matches the status --
#'   `"not_calibrated"` requires every beta `NA`, while `"calibrated"` /
#'   `"literature_proxy"` / `"example"` require every beta finite and a positive
#'   `nb_theta` on (and only on) the negative-binomial rows.
#' @param x A demand-parameter `data.frame` (e.g. from [read_urps_demand_params()]
#'   or `urps_demand_params()`).
#' @return Invisibly `TRUE` when valid; otherwise an error describing the first
#'   violated rule.
#' @seealso [urps_demand_params_schema()], [read_urps_demand_params()]
#' @family URPS demand
#' @examples
#' validate_urps_demand_params(urps_demand_params()) # the NA skeleton is valid
#' @export
validate_urps_demand_params <- function(x) {
  if (!is.data.frame(x)) {
    stop("[validate_urps_demand_params] `x` must be a data.frame.", call. = FALSE)
  }
  need <- urps_demand_params_schema()$column
  miss <- setdiff(need, names(x))
  if (length(miss)) {
    stop("[validate_urps_demand_params] missing required column(s): ",
      paste(miss, collapse = ", "), ".",
      call. = FALSE
    )
  }

  if (nrow(x) != length(.URPS_DEMAND_SERVICE_TYPES)) {
    stop(sprintf(
      "[validate_urps_demand_params] expected %d service rows, got %d.",
      length(.URPS_DEMAND_SERVICE_TYPES), nrow(x)
    ), call. = FALSE)
  }
  if (anyDuplicated(x$service_type)) {
    stop("[validate_urps_demand_params] `service_type` must be unique.", call. = FALSE)
  }
  if (!setequal(x$service_type, .URPS_DEMAND_SERVICE_TYPES)) {
    stop("[validate_urps_demand_params] `service_type` must be exactly: ",
      paste(.URPS_DEMAND_SERVICE_TYPES, collapse = ", "), ".",
      call. = FALSE
    )
  }

  ord <- match(x$service_type, names(.URPS_DEMAND_MODEL_FORMS))
  if (!identical(as.character(x$model_form), unname(.URPS_DEMAND_MODEL_FORMS[ord]))) {
    stop("[validate_urps_demand_params] `model_form` does not match the fixed service -> form map.",
      call. = FALSE
    )
  }

  status <- unique(x$calibration_status)
  if (length(status) != 1L || !status %in% .URPS_DEMAND_CALIBRATION_STATES) {
    stop("[validate_urps_demand_params] `calibration_status` must be a single value in {",
      paste(.URPS_DEMAND_CALIBRATION_STATES, collapse = ", "), "}.",
      call. = FALSE
    )
  }

  if (!is.numeric(x$calibration_scalar) || any(is.na(x$calibration_scalar)) ||
    any(x$calibration_scalar <= 0)) {
    stop("[validate_urps_demand_params] `calibration_scalar` must be positive and non-NA.",
      call. = FALSE
    )
  }

  beta_mat <- x[, .URPS_DEMAND_BETA_COLS, drop = FALSE]
  all_na <- all(vapply(beta_mat, function(c) all(is.na(c)), logical(1)))
  all_fin <- all(vapply(beta_mat, function(c) all(is.finite(c)), logical(1)))
  is_nb <- x$model_form == "negative_binomial"

  if (status == "not_calibrated") {
    if (!all_na) {
      stop("[validate_urps_demand_params] calibration_status 'not_calibrated' requires every beta to be NA.",
        call. = FALSE
      )
    }
  } else {
    if (!all_fin) {
      stop(sprintf(
        "[validate_urps_demand_params] calibration_status '%s' requires every beta to be finite (no NA).",
        status
      ), call. = FALSE)
    }
    if (any(is.na(x$nb_theta[is_nb])) || any(x$nb_theta[is_nb] <= 0)) {
      stop("[validate_urps_demand_params] negative-binomial rows need a positive `nb_theta` when calibrated.",
        call. = FALSE
      )
    }
    if (any(!is.na(x$nb_theta[!is_nb]))) {
      stop("[validate_urps_demand_params] `nb_theta` must be NA for logistic / Poisson rows.",
        call. = FALSE
      )
    }
  }
  invisible(TRUE)
}

#' Read a fitted URPS demand-model parameter artifact
#'
#' @description Read a demand-parameter CSV produced by the calibration pipeline
#'   (`analysis/urps_demand/fit_urps_demand.R`), coerce the beta / scalar columns
#'   to double, and validate it against [validate_urps_demand_params()]. The
#'   returned frame is a drop-in for `urps_demand_params()` -- same columns, but
#'   with real coefficients and `calibration_status != "not_calibrated"`.
#' @param path Path to the parameter CSV.
#' @param validate Validate before returning (default `TRUE`). Leave `TRUE`
#'   unless you are deliberately inspecting a malformed artifact.
#' @return A demand-parameter `data.frame` carrying a `calibration_status`
#'   attribute for a quick top-level check.
#' @seealso [urps_demand_params_schema()], [validate_urps_demand_params()],
#'   [urps_demand_params()]
#' @family URPS demand
#' @examples
#' ex <- system.file("extdata", "urps_demand_params_example.csv",
#'   package = "mufflyaccess"
#' )
#' if (nzchar(ex)) {
#'   p <- read_urps_demand_params(ex)
#'   attr(p, "calibration_status")
#' }
#' @export
read_urps_demand_params <- function(path, validate = TRUE) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("[read_urps_demand_params] `path` must be a single existing file path.", call. = FALSE)
  }
  d <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  num_cols <- c(.URPS_DEMAND_BETA_COLS, "nb_theta", "calibration_scalar")
  for (col in intersect(num_cols, names(d))) d[[col]] <- as.double(d[[col]])
  if (isTRUE(validate)) validate_urps_demand_params(d)
  attr(d, "calibration_status") <- unique(d$calibration_status)
  d
}
