# The demand-calibration ingestion contract: schema, validator, and reader.
# R/urps_demand.R ships the NA skeleton; this file pins the OTHER half -- what a
# fitted parameter artifact must look like and how a malformed one fails loud --
# so the contract is guaranteed independent of the (restricted) survey data that
# eventually fills it. The bundled example CSV is a synthetic, typed stand-in for
# a real fit.

ex_path <- system.file("extdata", "urps_demand_params_example.csv",
                       package = "mufflyaccess")

test_that("the schema names the columns urps_demand_params() actually carries", {
  sch <- urps_demand_params_schema()
  expect_true(all(c("column", "type", "required", "description") %in% names(sch)))
  expect_true(all(sch$column %in% names(urps_demand_params())))
  # every service + model_form + beta + provenance column is declared
  expect_true(all(c("service_type", "model_form", "intercept", "b_age",
                    "nb_theta", "calibration_scalar", "calibration_status")
                  %in% sch$column))
})

test_that("the NA skeleton (not_calibrated) is a valid artifact", {
  expect_invisible(validate_urps_demand_params(urps_demand_params()))
  expect_true(validate_urps_demand_params(urps_demand_params()))
})

test_that("validate rejects structural violations", {
  skel <- urps_demand_params()
  expect_error(validate_urps_demand_params(skel[, setdiff(names(skel), "b_age")]),
               "missing required column")
  expect_error(validate_urps_demand_params(skel[-1, ]), "expected 6 service rows")
  dup <- skel; dup$service_type[2] <- dup$service_type[1]
  expect_error(validate_urps_demand_params(dup), "unique")
  badstatus <- skel; badstatus$calibration_status <- "totally_calibrated"
  expect_error(validate_urps_demand_params(badstatus), "calibration_status")
  badscalar <- skel; badscalar$calibration_scalar[1] <- 0
  expect_error(validate_urps_demand_params(badscalar), "calibration_scalar")
  expect_error(validate_urps_demand_params(list(a = 1)), "must be a data.frame")
})

test_that("read_urps_demand_params ingests + validates the bundled example", {
  skip_if(!nzchar(ex_path) || !file.exists(ex_path), "example artifact not bundled")
  p <- read_urps_demand_params(ex_path)
  expect_equal(nrow(p), 6L)
  expect_identical(attr(p, "calibration_status"), "example")
  expect_true(all(is.finite(p$intercept)))                 # calibrated => finite betas
  is_nb <- p$model_form == "negative_binomial"
  expect_true(all(is.finite(p$nb_theta[is_nb]) & p$nb_theta[is_nb] > 0))
  expect_true(all(is.na(p$nb_theta[!is_nb])))              # NA for logistic/poisson
  expect_invisible(validate_urps_demand_params(p))
})

test_that("a calibrated artifact with any NA beta, or a bad nb_theta pattern, is rejected", {
  skip_if(!nzchar(ex_path) || !file.exists(ex_path), "example artifact not bundled")
  p <- read_urps_demand_params(ex_path)

  na_beta <- p; na_beta$b_age[1] <- NA_real_
  expect_error(validate_urps_demand_params(na_beta), "finite")

  # negative-binomial row missing its dispersion
  no_theta <- p; no_theta$nb_theta[no_theta$model_form == "negative_binomial"][1] <- NA_real_
  expect_error(validate_urps_demand_params(no_theta), "nb_theta")

  # dispersion wrongly set on a logistic row
  extra_theta <- p; extra_theta$nb_theta[extra_theta$model_form == "logistic"][1] <- 1.0
  expect_error(validate_urps_demand_params(extra_theta), "nb_theta")
})

test_that("read_urps_demand_params errors on a missing path", {
  expect_error(read_urps_demand_params("/no/such/file.csv"), "existing file path")
})

# ---- activation hook: option/env -> urps_demand_params() serves the fit -------

test_that("with no artifact configured, the skeleton is served and demand is NA", {
  old <- options(mufflyaccess.urps_demand_params_path = NULL); on.exit(options(old), add = TRUE)
  Sys.unsetenv("MUFFLYACCESS_URPS_DEMAND_PARAMS")
  expect_identical(unique(urps_demand_params()$calibration_status), "not_calibrated")
  pop <- data.frame(n = 1000, age = 50, sex_male = 0, bmi = 28)
  expect_true(is.na(urps_demand_fte(pop, visits_per_fte = 2000)))
})

test_that("configuring a fitted artifact activates demand end to end", {
  skip_if(!nzchar(ex_path) || !file.exists(ex_path), "example artifact not bundled")
  old <- options(mufflyaccess.urps_demand_params_path = ex_path); on.exit(options(old), add = TRUE)

  expect_identical(unique(urps_demand_params()$calibration_status), "example")
  pop <- data.frame(n = c(1000, 2000), age = c(50, 65), sex_male = 0, bmi = c(28, 31))
  d <- urps_demand_clinical_fte(pop, visits_per_fte = 2000)
  expect_true(is.finite(d) && d > 0)                       # no longer NA once activated
  # demand is linear in population count
  d2 <- urps_demand_clinical_fte(transform(pop, n = n * 2), visits_per_fte = 2000)
  expect_equal(d2, 2 * d)
  # shifting office demand to retail clinics lowers URPS physician demand
  d_retail <- urps_demand_clinical_fte(pop, visits_per_fte = 2000, retail_clinic_share = 0.25)
  expect_lt(d_retail, d)
  # gap wires through: gap = demand - supply
  expect_equal(urps_gap_fte(0.5, d), d - 0.5)
})

test_that("a misconfigured artifact path fails loud (never silently NA)", {
  old <- options(mufflyaccess.urps_demand_params_path = "/no/such/fit.csv")
  on.exit(options(old), add = TRUE)
  expect_error(urps_demand_params(), "existing file path")
})
