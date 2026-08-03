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
