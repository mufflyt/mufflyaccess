library(testthat)

# urps_demand.R: healthcare use prediction equation skeleton.

# ---- version -----------------------------------------------------------------

test_that("URPS_DEMAND_VERSION is semver and pre-calibration (0.x.x)", {
  expect_match(URPS_DEMAND_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  expect_match(URPS_DEMAND_VERSION, "^0\\.")  # pre-calibration convention
})

# ---- params table ------------------------------------------------------------

test_that("params table has exactly 6 rows with required columns", {
  d <- urps_demand_params()
  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), 6L)
  expect_true(all(c("service_type", "model_form", "outcome_units",
                    "intercept", "b_age", "b_sex_male",
                    "b_race_black", "b_race_hispanic", "b_race_other",
                    "b_bmi", "b_smoking_current",
                    "b_income_low", "b_income_mid",
                    "b_insurance_medicaid", "b_insurance_medicare",
                    "b_insurance_uninsured", "b_managed_care",
                    "b_chronic_count", "b_urban",
                    "nb_theta", "calibration_scalar",
                    "data_source", "calibration_status") %in% names(d)))
})

test_that("service_types are unique and cover the expected set", {
  d <- urps_demand_params()
  expected <- c("office_visit", "outpatient_visit", "home_health_visit",
                "hospitalization_prob", "ed_visit_prob", "hospital_los")
  expect_setequal(d$service_type, expected)
  expect_equal(anyDuplicated(d$service_type), 0L)
})

test_that("model forms match service types", {
  d <- urps_demand_params()
  expect_equal(d$model_form[d$service_type == "office_visit"],       "negative_binomial")
  expect_equal(d$model_form[d$service_type == "outpatient_visit"],   "negative_binomial")
  expect_equal(d$model_form[d$service_type == "home_health_visit"],  "negative_binomial")
  expect_equal(d$model_form[d$service_type == "hospitalization_prob"], "logistic")
  expect_equal(d$model_form[d$service_type == "ed_visit_prob"],      "logistic")
  expect_equal(d$model_form[d$service_type == "hospital_los"],       "poisson")
})

test_that("all calibration_status values are 'not_calibrated'", {
  d <- urps_demand_params()
  expect_true(all(d$calibration_status == "not_calibrated"))
})

test_that("all beta coefficients are NA (skeleton, not yet fitted)", {
  d <- urps_demand_params()
  beta_cols <- c("intercept", "b_age", "b_sex_male",
                 "b_race_black", "b_race_hispanic", "b_race_other",
                 "b_bmi", "b_smoking_current",
                 "b_income_low", "b_income_mid",
                 "b_insurance_medicaid", "b_insurance_medicare",
                 "b_insurance_uninsured", "b_managed_care",
                 "b_chronic_count", "b_urban")
  for (col in beta_cols)
    expect_true(all(is.na(d[[col]])), label = paste("beta NA:", col))
})

test_that("nb_theta is NA for logistic and Poisson, and NA for NB (skeleton)", {
  d <- urps_demand_params()
  # All NA in skeleton; logistic/Poisson must stay NA after calibration too
  non_nb <- d$model_form != "negative_binomial"
  expect_true(all(is.na(d$nb_theta[non_nb])))
})

test_that("calibration_scalar is 1.0 (identity placeholder)", {
  d <- urps_demand_params()
  expect_true(all(d$calibration_scalar == 1.0))
})

test_that("params table carries source, formula_note, and covariate_reference attributes", {
  d <- urps_demand_params()
  expect_false(is.null(attr(d, "source")))
  expect_match(attr(d, "formula_note"),        "intercept")
  expect_match(attr(d, "covariate_reference"), "female")
})

# ---- urps_demand_levers ------------------------------------------------------

test_that("urps_demand_levers returns a named list with all four demand levers", {
  lv <- urps_demand_levers("baseline")
  expect_type(lv, "list")
  expect_true(all(c("demand_obesity_prev_shift", "demand_insurance_expansion_factor",
                    "demand_managed_care_factor", "demand_retail_clinic_share",
                    "requires_demand_model", "registry_version") %in% names(lv)))
})

test_that("baseline demand levers are all neutral", {
  lv <- urps_demand_levers("baseline")
  expect_equal(lv$demand_obesity_prev_shift,         0.0)
  expect_equal(lv$demand_insurance_expansion_factor, 1.0)
  expect_equal(lv$demand_managed_care_factor,        1.0)
  expect_equal(lv$demand_retail_clinic_share,        0.0)
  expect_false(lv$requires_demand_model)
})

test_that("managed_care_increase levers are correctly retrieved", {
  lv <- urps_demand_levers("demand_managed_care_increase")
  expect_equal(lv$demand_managed_care_factor, 0.85)
  expect_equal(lv$demand_retail_clinic_share, 0.0)
  expect_true(lv$requires_demand_model)
})

test_that("retail_clinic_shift levers are correctly retrieved", {
  lv <- urps_demand_levers("demand_retail_clinic_shift")
  expect_equal(lv$demand_retail_clinic_share, 0.10)
  expect_equal(lv$demand_managed_care_factor, 1.0)
  expect_true(lv$requires_demand_model)
})

test_that("urps_demand_levers fails loud on unknown scenario", {
  expect_error(urps_demand_levers("no_such_scenario"), "unknown scenario_id")
})

# ---- urps_demand_clinical_fte ------------------------------------------------

test_that("urps_demand_clinical_fte returns NA_real_ when not calibrated", {
  pop <- data.frame(age = 50, sex = "female", n = 1000)
  result <- urps_demand_clinical_fte(pop, visits_per_fte = 2000)
  expect_true(is.na(result))
  expect_type(result, "double")
})

test_that("urps_demand_clinical_fte NA result is length 1", {
  pop <- data.frame(age = 50:60, sex = "female", n = rep(100, 11))
  expect_length(urps_demand_clinical_fte(pop, visits_per_fte = 2000), 1L)
})

test_that("urps_demand_clinical_fte accepts demand lever arguments without error", {
  pop <- data.frame(age = 50, sex = "female", n = 1000)
  lv  <- urps_demand_levers("demand_managed_care_increase")
  result <- urps_demand_clinical_fte(pop, visits_per_fte = 2000,
    managed_care_factor = lv$demand_managed_care_factor,
    retail_clinic_share = lv$demand_retail_clinic_share)
  expect_true(is.na(result))
})

test_that("urps_demand_clinical_fte fails loud on invalid lever values", {
  pop <- data.frame(age = 50, sex = "female", n = 1000)
  expect_error(urps_demand_clinical_fte(pop, 2000, managed_care_factor = 0),  "positive")
  expect_error(urps_demand_clinical_fte(pop, 2000, managed_care_factor = -1), "positive")
  expect_error(urps_demand_clinical_fte(pop, 2000, retail_clinic_share = 1),  "\\[0, 1\\)")
  expect_error(urps_demand_clinical_fte(pop, 2000, retail_clinic_share = -0.1), "\\[0, 1\\)")
})

test_that("urps_demand_levers output plugs directly into urps_demand_clinical_fte", {
  pop <- data.frame(age = 50, sex = "female", n = 1000)
  for (id in c("baseline", "demand_managed_care_increase", "demand_retail_clinic_shift")) {
    lv <- urps_demand_levers(id)
    result <- urps_demand_clinical_fte(pop, visits_per_fte = 2000,
      obesity_prev_shift         = lv$demand_obesity_prev_shift,
      insurance_expansion_factor = lv$demand_insurance_expansion_factor,
      managed_care_factor        = lv$demand_managed_care_factor,
      retail_clinic_share        = lv$demand_retail_clinic_share)
    expect_true(is.na(result), label = paste("NA for", id))
  }
})

# ---- urps_demand_fte (scenario-aware wrapper) --------------------------------

test_that("urps_demand_fte returns NA_real_ for all scenarios (not yet calibrated)", {
  pop <- data.frame(age = 50, sex = "female", n = 10000)
  for (id in urps_scenario_ids()) {
    result <- urps_demand_fte(pop, visits_per_fte = 2000, scenario_id = id)
    expect_true(is.na(result), label = paste("NA for", id))
    expect_type(result, "double")
  }
})

test_that("urps_demand_fte defaults to baseline scenario", {
  pop <- data.frame(age = 50, sex = "female", n = 10000)
  expect_equal(
    urps_demand_fte(pop, 2000),
    urps_demand_fte(pop, 2000, scenario_id = "baseline"))
})

test_that("urps_demand_fte fails loud on unknown scenario", {
  pop <- data.frame(age = 50, sex = "female", n = 10000)
  expect_error(urps_demand_fte(pop, 2000, scenario_id = "no_such"), "unknown scenario_id")
})

test_that("urps_demand_fte is equivalent to calling urps_demand_clinical_fte with levers", {
  pop <- data.frame(age = 50, sex = "female", n = 10000)
  lv  <- urps_demand_levers("demand_managed_care_increase")
  expect_equal(
    urps_demand_fte(pop, 2000, "demand_managed_care_increase"),
    urps_demand_clinical_fte(pop, 2000,
      obesity_prev_shift         = lv$demand_obesity_prev_shift,
      insurance_expansion_factor = lv$demand_insurance_expansion_factor,
      managed_care_factor        = lv$demand_managed_care_factor,
      retail_clinic_share        = lv$demand_retail_clinic_share))
})

# ---- urps_gap_fte ------------------------------------------------------------

test_that("urps_gap_fte computes demand minus supply correctly", {
  expect_equal(urps_gap_fte(1200, 1450),  250)   # shortage
  expect_equal(urps_gap_fte(1400, 1200), -200)   # surplus
  expect_equal(urps_gap_fte(1000, 1000),    0)   # balanced
})

test_that("urps_gap_fte returns NA_real_ when either argument is NA", {
  expect_true(is.na(urps_gap_fte(1200,    NA_real_)))
  expect_true(is.na(urps_gap_fte(NA_real_, 1450)))
  expect_true(is.na(urps_gap_fte(NA_real_, NA_real_)))
})

test_that("urps_gap_fte is consistent with the projection contract gap identity", {
  supply <- 1200; demand <- 1450
  gap    <- urps_gap_fte(supply, demand)
  expect_equal(gap, demand - supply, tolerance = 1e-9)
})

test_that("urps_gap_fte fails loud on non-numeric or non-scalar inputs", {
  expect_error(urps_gap_fte(c(1200, 1300), 1450), "length-1")
  expect_error(urps_gap_fte(1200, c(1450, 1500)), "length-1")
  expect_error(urps_gap_fte("a", 1450),            "length-1")
})

test_that("supply + demand + gap round-trip with urps_demand_fte", {
  pop    <- data.frame(age = 50, sex = "female", n = 10000)
  supply <- 1200
  demand <- urps_demand_fte(pop, 2000, "baseline")  # NA until calibrated
  gap    <- urps_gap_fte(supply, demand)
  expect_true(is.na(gap))   # NA propagates correctly
})
