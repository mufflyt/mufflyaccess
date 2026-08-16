# ==============================================================================
# URPS healthcare use prediction equation parameter skeleton.
#
# Mirrors the IHS Markit HWMM approach (v5.19.20):
#   - Negative binomial regression for count outcomes (office visits,
#     outpatient visits, home health visits)
#   - Logistic regression for binary outcomes (hospitalization probability,
#     ED visit probability, by ICD diagnosis category)
#   - Poisson regression for hospital length of stay
#
# Covariates per HWMM Exhibits 14-16:
#   age, sex, race/ethnicity, BMI, smoking, income (FPL category),
#   insurance type, managed care enrollment, chronic condition count,
#   urban-rural status
#
# Data source: MEPS 2013-2017 (~170k persons), calibrated against
# NAMCS / NHAMCS / NIS national totals via multiplicative scalars
# (see urps_demand_scalars()).
#
# CURRENT STATUS: calibration_status = "not_calibrated"
#   All regression coefficients are NA_real_. The table structure matches the
#   HWMM specification so cliff can wire demand_clinical_fte into the
#   projection contract now; the coefficients slot in when MEPS or NAMCS data
#   are fitted for URPS / FPMRS services.
#
# Data acquisition path to calibrate:
#   1. NAMCS/NHAMCS restricted-use files filtered to URPS specialty codes
#   2. MEPS 2013-2017 individual-level survey data (AHRQ Data Center)
#   3. Fit NB/logistic/Poisson models with survey weights (survey::svyglm)
#   4. Apply NAMCS/NHAMCS/NIS calibration scalars (urps_demand_scalars())
#
# Reference encoding (same as HWMM):
#   sex:       female = 0, male = 1
#   race:      non-Hispanic white = reference
#   income:    >= 400% FPL = reference
#   insurance: private = reference
#
# URPS-specific note: MEPS does not contain FPMRS procedure codes directly.
# Until NAMCS data arrive, b_* columns remain NA and demand_clinical_fte
# in the projection contract is NA (allowed by the contract schema).
# ==============================================================================

.URPS_DEMAND_VERSION <- "0.1.0" # pre-calibration; bump to 1.0.0 on first fit

.urps_demand_params_df <- function() {
  service_types <- c(
    "office_visit",
    "outpatient_visit",
    "home_health_visit",
    "hospitalization_prob",
    "ed_visit_prob",
    "hospital_los"
  )
  model_forms <- c(
    "negative_binomial", # office_visit
    "negative_binomial", # outpatient_visit
    "negative_binomial", # home_health_visit
    "logistic", # hospitalization_prob
    "logistic", # ed_visit_prob
    "poisson" # hospital_los
  )
  outcome_units <- c(
    "annual_visit_count", # office_visit
    "annual_visit_count", # outpatient_visit
    "annual_visit_count", # home_health_visit
    "probability_0_1", # hospitalization_prob
    "probability_0_1", # ed_visit_prob
    "days_per_admission" # hospital_los
  )
  n <- length(service_types)
  data.frame(
    service_type               = service_types,
    model_form                 = model_forms,
    outcome_units              = outcome_units,
    # ---- regression coefficients (all NA until MEPS/NAMCS fit) ---------------
    intercept                  = rep(NA_real_, n),
    b_age                      = rep(NA_real_, n), # continuous, per year
    b_sex_male                 = rep(NA_real_, n), # ref: female
    b_race_black               = rep(NA_real_, n), # ref: non-Hispanic white
    b_race_hispanic            = rep(NA_real_, n),
    b_race_other               = rep(NA_real_, n),
    b_bmi                      = rep(NA_real_, n), # continuous, per unit
    b_smoking_current          = rep(NA_real_, n), # ref: never/former
    b_income_low               = rep(NA_real_, n), # < 100% FPL; ref: >= 400% FPL
    b_income_mid               = rep(NA_real_, n), # 100-399% FPL
    b_insurance_medicaid       = rep(NA_real_, n), # ref: private
    b_insurance_medicare       = rep(NA_real_, n),
    b_insurance_uninsured      = rep(NA_real_, n),
    b_managed_care             = rep(NA_real_, n), # 1 = in managed care plan
    b_chronic_count            = rep(NA_real_, n), # count of chronic conditions
    b_urban                    = rep(NA_real_, n), # 1 = urban; ref: rural
    # ---- dispersion parameter (negative binomial only; NA otherwise) ----------
    nb_theta                   = rep(NA_real_, n),
    # ---- calibration scalar slot (see urps_demand_scalars()) ------------------
    calibration_scalar         = rep(1.0, n), # placeholder; overwritten at fit
    # ---- provenance -----------------------------------------------------------
    data_source                = "MEPS_2013_2017",
    calibration_status         = "not_calibrated",
    stringsAsFactors           = FALSE
  )
}

# Load-time validation -- structural guarantees that survive a future
# accidental edit, even before any betas are filled in.
local({
  d <- .urps_demand_params_df()
  expected_services <- c(
    "office_visit", "outpatient_visit", "home_health_visit",
    "hospitalization_prob", "ed_visit_prob", "hospital_los"
  )
  expected_forms <- c(
    "negative_binomial", "negative_binomial", "negative_binomial",
    "logistic", "logistic", "poisson"
  )
  beta_cols <- c(
    "intercept", "b_age", "b_sex_male",
    "b_race_black", "b_race_hispanic", "b_race_other",
    "b_bmi", "b_smoking_current",
    "b_income_low", "b_income_mid",
    "b_insurance_medicaid", "b_insurance_medicare", "b_insurance_uninsured",
    "b_managed_care", "b_chronic_count", "b_urban"
  )
  stopifnot(
    "demand params must have exactly 6 rows" =
      nrow(d) == 6L,
    "service_type must be unique" =
      !anyDuplicated(d$service_type),
    "service_types must be the expected set" =
      setequal(d$service_type, expected_services),
    "model forms match service types" =
      identical(d$model_form[match(expected_services, d$service_type)], expected_forms),
    "all required covariate columns present" =
      all(beta_cols %in% names(d)),
    "calibration_status must be 'not_calibrated' (skeleton)" =
      all(d$calibration_status == "not_calibrated"),
    "all beta columns must be NA_real_ in the skeleton" =
      all(vapply(beta_cols, function(col) all(is.na(d[[col]])), logical(1))),
    "nb_theta must be NA for logistic and Poisson models" = {
      is_nb <- d$model_form == "negative_binomial"
      all(is.na(d$nb_theta[!is_nb]))
    },
    "calibration_scalar must be positive" =
      all(d$calibration_scalar > 0),
    "demand version must be semver" =
      grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", .URPS_DEMAND_VERSION)
  )
})

#' Version of the URPS demand prediction equation skeleton
#'
#' @description Pre-calibration version `"0.1.0"` -- structure matches the HWMM
#'   specification but all regression coefficients are `NA`. Bump to `"1.0.0"` on
#'   first MEPS/NAMCS fit.
#' @format Length-1 character string.
#' @seealso [urps_demand_params()], [urps_demand_scalars()]
#' @family URPS demand
#' @examples
#' URPS_DEMAND_VERSION
#' @export
URPS_DEMAND_VERSION <- .URPS_DEMAND_VERSION

# Resolve a configured fitted-params artifact (option first, then env var). NULL
# when unset -> urps_demand_params() serves the NA skeleton (the default). When
# set, urps_demand_params() delegates to read_urps_demand_params(), which
# validates the artifact and fails loud on a malformed / missing one.
.urps_demand_params_source <- function() {
  p <- getOption("mufflyaccess.urps_demand_params_path",
    default = Sys.getenv("MUFFLYACCESS_URPS_DEMAND_PARAMS", "")
  )
  if (is.character(p) && length(p) == 1L && nzchar(p)) p else NULL
}

#' URPS healthcare use prediction equation parameters (skeleton)
#'
#' @description The regression parameter skeleton for six URPS-relevant service
#'   types following the IHS Markit HWMM specification:
#'
#'   | Service | Model | Outcome |
#'   |---|---|---|
#'   | Office visits | Negative binomial | Annual count |
#'   | Outpatient visits | Negative binomial | Annual count |
#'   | Home health visits | Negative binomial | Annual count |
#'   | Hospitalization probability | Logistic | Probability |
#'   | ED visit probability | Logistic | Probability |
#'   | Hospital length of stay | Poisson | Days/admission |
#'
#'   **Status:** `calibration_status = "not_calibrated"` -- all beta columns are
#'   `NA_real_`. The structure exists so cliff can wire [urps_demand_clinical_fte()]
#'   into the projection contract today. Coefficients populate when MEPS 2013-2017
#'   or NAMCS restricted-use data are fitted for URPS / FPMRS services.
#'
#'   **Covariates (columns `b_*`):** age, sex, race/ethnicity, BMI, smoking,
#'   income (FPL category), insurance type, managed care enrollment, chronic
#'   condition count, urban-rural. Reference encoding follows HWMM:
#'   female = reference sex, non-Hispanic white = reference race,
#'   >= 400% FPL = reference income, private insurance = reference.
#'
#' @return A `data.frame` with columns `service_type`, `model_form`,
#'   `outcome_units`, covariate beta columns (`b_*`), `nb_theta`,
#'   `calibration_scalar`, `data_source`, and `calibration_status`. Carries
#'   attributes `source`, `formula_note`, and `covariate_reference`.
#' @seealso [urps_demand_scalars()], [urps_demand_clinical_fte()],
#'   [URPS_DEMAND_VERSION]
#' @family URPS demand
#' @examples
#' urps_demand_params()
#' urps_demand_params()[, c("service_type", "model_form", "calibration_status")]
#' @export
urps_demand_params <- function() {
  configured <- .urps_demand_params_source()
  if (!is.null(configured)) {
    return(read_urps_demand_params(configured))
  } # activated fit
  d <- .urps_demand_params_df()
  attr(d, "source") <- paste(
    "IHS Markit HWMM v5.19.20 (model structure, covariate list, Exhibits 14-16);",
    "MEPS 2013-2017 (~170k persons, AHRQ Data Center) -- fitting dataset;",
    "NAMCS/NHAMCS/NIS -- calibration totals for specialty x setting scalars.",
    "URPS-specific fit pending; see urps_demand_scalars() for scalar skeleton."
  )
  attr(d, "formula_note") <- paste(
    "NB: E[visits] = exp(intercept + b_age*age + ... + b_urban*urban);",
    "Logistic: logit(P) = intercept + b_age*age + ...;",
    "Poisson: E[LOS] = exp(intercept + b_age*age + ...)"
  )
  attr(d, "covariate_reference") <- paste(
    "Reference levels: sex=female, race=non-Hispanic white,",
    "income >= 400% FPL, insurance=private."
  )
  d
}

#' Retrieve demand lever settings for a scenario (cliff integration helper)
#'
#' @description Returns the four demand lever values for a registered scenario
#'   as a named list, suitable for passing directly to [urps_demand_clinical_fte()].
#'   This is the demand-side counterpart to [urps_scenario()]: cliff calls this
#'   once per scenario to get the full demand lever bundle.
#'
#' @details **Lever semantics:**
#'   \describe{
#'     \item{`demand_obesity_prev_shift`}{Percentage-point shift in population
#'       obesity prevalence applied on top of baseline trends. Positive = higher
#'       obesity, increasing PFD incidence and visit rates.}
#'     \item{`demand_insurance_expansion_factor`}{Multiplier on the utilization
#'       contribution of previously uninsured / underinsured persons. > 1 means
#'       more demand from insurance expansion.}
#'     \item{`demand_managed_care_factor`}{Multiplier on total physician demand
#'       from changes in HMO/ACO gatekeeping intensity. < 1 means managed care
#'       reduces specialist referrals and direct access.}
#'     \item{`demand_retail_clinic_share`}{Fraction of office-visit demand
#'       shifted to retail health clinics (staffed by APRNs/PAs for lower-acuity
#'       conditions). Reduces URPS physician demand proportionally.}
#'   }
#'
#' @param scenario_id A registered scenario id (see [urps_scenario_ids()]).
#' @return A named list with elements `demand_obesity_prev_shift`,
#'   `demand_insurance_expansion_factor`, `demand_managed_care_factor`, and
#'   `demand_retail_clinic_share`. Also carries `scenario_id`,
#'   `requires_demand_model`, and `registry_version`.
#' @seealso [urps_scenario()], [urps_demand_clinical_fte()], [urps_demand_params()]
#' @family URPS demand
#' @examples
#' urps_demand_levers("baseline")
#' urps_demand_levers("demand_managed_care_increase")
#' urps_demand_levers("demand_retail_clinic_shift")
#' @export
urps_demand_levers <- function(scenario_id) {
  sc <- urps_scenario(scenario_id)
  list(
    scenario_id                       = sc$scenario_id,
    demand_obesity_prev_shift         = sc$demand_obesity_prev_shift,
    demand_insurance_expansion_factor = sc$demand_insurance_expansion_factor,
    demand_managed_care_factor        = sc$demand_managed_care_factor,
    demand_retail_clinic_share        = sc$demand_retail_clinic_share,
    requires_demand_model             = sc$requires_demand_model,
    registry_version                  = sc$registry_version
  )
}

#' Compute demand_clinical_fte from a patient population and the fitted equations
#'
#' @description Predicted ambulatory-visit demand for a patient population,
#'   converted to clinical FTE. **Returns `NA_real_` while the demand model is
#'   uncalibrated** (the `urps_demand_params()` NA skeleton). Once a fitted
#'   artifact is active -- `options(mufflyaccess.urps_demand_params_path = ...)` or
#'   `MUFFLYACCESS_URPS_DEMAND_PARAMS`, see [read_urps_demand_params()] -- it
#'   evaluates the visit-count regressions per person, sums over the population,
#'   applies the scenario demand levers, and divides by `visits_per_fte`.
#'
#' @details The pipeline, evaluated once `urps_demand_params()` is calibrated
#'   (office + outpatient visit-count services drive office-based URPS FTE):
#'   1. For each service type, evaluate the regression at each person's covariate
#'      vector to get predicted visit rate.
#'   2. Multiply by person count -> expected visits.
#'   3. Apply demand scenario levers:
#'      - `obesity_prev_shift`: adjusts PFD-relevant covariate distribution.
#'      - `insurance_expansion_factor`: scales visits from newly insured persons.
#'      - `managed_care_factor`: multiplies total specialist visit demand.
#'      - `retail_clinic_share`: reduces physician demand by the share of visits
#'        that shift to retail clinics (`visits_physician = visits_total * (1 - share)`).
#'   4. Multiply by specialty x setting calibration scalar (`urps_demand_scalars()`).
#'   5. Divide by `visits_per_fte` -> `demand_clinical_fte`.
#'
#'   Use [urps_demand_levers()] to retrieve a scenario's lever bundle from the
#'   registry rather than passing raw numeric values.
#'
#' @param population A `data.frame` with columns matching the `b_*` covariate
#'   names in [urps_demand_params()] (age, sex, race, bmi, etc.) and a column
#'   `n` (population count per row).
#' @param visits_per_fte Annual URPS visits per full-time-equivalent provider
#'   (visits -> FTE conversion denominator). No default; must be supplied.
#' @param obesity_prev_shift See [urps_demand_levers()]. Default `0`.
#' @param insurance_expansion_factor See [urps_demand_levers()]. Default `1`.
#' @param managed_care_factor Multiplier on total physician demand from HMO/ACO
#'   gatekeeping. Default `1` (no change). See [urps_demand_levers()].
#' @param retail_clinic_share Fraction of office-visit demand shifted to retail
#'   clinics, reducing URPS physician demand. Must be in \[0, 1). Default `0`.
#'   See [urps_demand_levers()].
#' @return Length-1 numeric `demand_clinical_fte` when the demand model is
#'   calibrated; `NA_real_` while it is the uncalibrated skeleton. `population`
#'   is a design-matrix `data.frame`: an `n` count column plus covariate columns
#'   named as the fit's design terms (`age`, `sex_male`, `race_black`, `bmi`,
#'   ...); an absent covariate is taken at its reference level (`0`).
#' @seealso [urps_demand_params()], [urps_demand_scalars()], [urps_demand_levers()]
#' @family URPS demand
#' @examples
#' levers <- urps_demand_levers("demand_managed_care_increase")
#' urps_demand_clinical_fte(
#'   population = data.frame(age = 50, sex = "female", n = 1000),
#'   visits_per_fte = 2000,
#'   managed_care_factor = levers$demand_managed_care_factor,
#'   retail_clinic_share = levers$demand_retail_clinic_share
#' ) # NA_real_ until calibrated
#' @export
urps_demand_clinical_fte <- function(population, visits_per_fte,
                                     obesity_prev_shift = 0,
                                     insurance_expansion_factor = 1,
                                     managed_care_factor = 1,
                                     retail_clinic_share = 0) {
  if (!is.numeric(managed_care_factor) || managed_care_factor <= 0) {
    stop("[urps_demand_clinical_fte] `managed_care_factor` must be a positive number.", call. = FALSE)
  }
  if (!is.numeric(retail_clinic_share) || retail_clinic_share < 0 || retail_clinic_share >= 1) {
    stop("[urps_demand_clinical_fte] `retail_clinic_share` must be in [0, 1).", call. = FALSE)
  }
  params <- urps_demand_params()
  if (all(is.na(params$intercept))) {
    return(NA_real_)
  } # NA skeleton -> demand NA

  # ---- calibrated path: predicted ambulatory-visit demand -> clinical FTE -----
  if (!is.data.frame(population) || !"n" %in% names(population)) {
    stop("[urps_demand_clinical_fte] `population` must be a data.frame with an `n` column ",
      "and design-matrix covariate columns (age, sex_male, race_*, bmi, ...).",
      call. = FALSE
    )
  }
  if (!is.numeric(visits_per_fte) || length(visits_per_fte) != 1L ||
    is.na(visits_per_fte) || visits_per_fte <= 0) {
    stop("[urps_demand_clinical_fte] `visits_per_fte` must be a positive number.", call. = FALSE)
  }

  # Office-based URPS physician FTE is driven by the ambulatory visit-count
  # services (office + outpatient); the inpatient / ED / home-health rows are a
  # different setting and do not enter office-based FTE. This is the documented
  # default estimand -- adjust here if the FTE definition changes.
  visit_services <- c("office_visit", "outpatient_visit")
  term_map <- c(
    b_age = "age", b_sex_male = "sex_male",
    b_race_black = "race_black", b_race_hispanic = "race_hispanic", b_race_other = "race_other",
    b_bmi = "bmi", b_smoking_current = "smoking_current",
    b_income_low = "income_low", b_income_mid = "income_mid",
    b_insurance_medicaid = "ins_medicaid", b_insurance_medicare = "ins_medicare",
    b_insurance_uninsured = "ins_uninsured", b_managed_care = "managed_care",
    b_chronic_count = "chronic_count", b_urban = "urban"
  )
  col <- function(nm) {
    if (nm %in% names(population)) {
      as.numeric(population[[nm]])
    } else {
      rep(0, nrow(population))
    }
  } # absent covariate = reference level (0)
  n <- as.numeric(population$n)

  total_visits <- 0
  for (svc in visit_services) {
    r <- params[params$service_type == svc, , drop = FALSE]
    lp <- rep(r$intercept, nrow(population))
    for (b in names(term_map)) lp <- lp + r[[b]] * col(term_map[[b]])
    rate <- exp(lp) # NB: E[annual visits | x]
    total_visits <- total_visits + sum(rate * n) * r$calibration_scalar
  }

  # Scenario demand levers (documented multiplicative adjustments):
  #   insurance_expansion_factor, managed_care_factor -> scale total demand;
  #   retail_clinic_share -> share of office demand shifted off URPS physicians;
  #   obesity_prev_shift  -> first-order proportional PFD-demand bump (pp / 100).
  total_visits <- total_visits * insurance_expansion_factor * managed_care_factor *
    (1 - retail_clinic_share) * (1 + obesity_prev_shift / 100)

  total_visits / visits_per_fte # visits -> clinical FTE
}

#' Scenario-aware demand FTE: registry lookup + clinical FTE in one call
#'
#' @description The demand-side counterpart to [urps_supply_fte_sex()]. Looks up
#'   the demand lever bundle for a registered scenario via [urps_demand_levers()],
#'   then calls [urps_demand_clinical_fte()] -- so cliff passes a `scenario_id`
#'   string rather than four raw lever values:
#'
#'   ```r
#'   # Supply side (cliff already does this):
#'   supply_fte <- mufflyaccess::urps_supply_fte_sex(cohort, baseline_scale,
#'                   late_from_age = sc$late_career_fte_onset_age,
#'                   late_factor   = sc$late_career_fte_factor)
#'
#'   # Demand side (new -- call this once per projection row):
#'   demand_fte <- mufflyaccess::urps_demand_fte(population, visits_per_fte,
#'                   scenario_id = scenario_id)
#'
#'   # Gap (close the triangle):
#'   gap_fte <- mufflyaccess::urps_gap_fte(supply_fte, demand_fte)
#'   ```
#'
#'   Returns `NA_real_` for any scenario while `urps_demand_params()` is the
#'   uncalibrated skeleton, and a real `demand_clinical_fte` once a fitted
#'   artifact is active (`calibration_status != "not_calibrated"`; see
#'   [read_urps_demand_params()]). Cliff can call this unconditionally -- the `NA`
#'   propagates to `gap_fte` and the contract validator allows `NA` in optional
#'   columns, and it simply stops being `NA` after activation.
#'
#' @param population A `data.frame` -- see [urps_demand_clinical_fte()].
#' @param visits_per_fte Annual URPS visits per FTE provider. See
#'   [urps_demand_clinical_fte()].
#' @param scenario_id A registered scenario id (default `"baseline"`). The
#'   four demand levers are resolved from the registry; passing raw lever values
#'   is not required.
#' @return Length-1 numeric `demand_clinical_fte`, or `NA_real_` until calibrated.
#' @seealso [urps_demand_clinical_fte()], [urps_demand_levers()],
#'   [urps_supply_fte_sex()], [urps_gap_fte()]
#' @family URPS demand
#' @examples
#' pop <- data.frame(age = 50, sex = "female", n = 10000)
#' urps_demand_fte(pop, visits_per_fte = 2000) # NA
#' urps_demand_fte(pop, visits_per_fte = 2000, scenario_id = "baseline") # NA
#' urps_demand_fte(pop, 2000, scenario_id = "demand_managed_care_increase") # NA
#' @export
urps_demand_fte <- function(population, visits_per_fte, scenario_id = "baseline") {
  lv <- urps_demand_levers(scenario_id)
  urps_demand_clinical_fte(
    population,
    visits_per_fte             = visits_per_fte,
    obesity_prev_shift         = lv$demand_obesity_prev_shift,
    insurance_expansion_factor = lv$demand_insurance_expansion_factor,
    managed_care_factor        = lv$demand_managed_care_factor,
    retail_clinic_share        = lv$demand_retail_clinic_share
  )
}
