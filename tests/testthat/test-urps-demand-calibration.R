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
