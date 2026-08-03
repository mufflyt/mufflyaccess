library(testthat)

# urps_demand_scalars.R: specialty × setting calibration scalar skeleton.

# ---- version -----------------------------------------------------------------

test_that("URPS_DEMAND_SCALARS_VERSION is semver and pre-calibration", {
  expect_match(URPS_DEMAND_SCALARS_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  expect_match(URPS_DEMAND_SCALARS_VERSION, "^0\\.")
})

# ---- scalar table ------------------------------------------------------------

test_that("scalar table has exactly 6 rows with required columns", {
  d <- urps_demand_scalars()
  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), 6L)
  expect_true(all(c("specialty", "setting", "scalar",
                    "calibration_source", "calibration_status") %in% names(d)))
})

test_that("settings are unique and cover the expected set including retail_clinic", {
  d <- urps_demand_scalars()
  expected <- c("office", "outpatient", "home_health", "inpatient", "ed", "retail_clinic")
  expect_setequal(d$setting, expected)
  expect_equal(anyDuplicated(d$setting), 0L)
})

test_that("retail_clinic setting has NAMCS calibration source", {
  d <- urps_demand_scalars()
  rc <- d[d$setting == "retail_clinic", ]
  expect_true(grepl("NAMCS", rc$calibration_source))
  expect_equal(rc$scalar, 1.0)
  expect_equal(rc$calibration_status, "not_calibrated")
})

test_that("urps_demand_scalar returns 1.0 for retail_clinic", {
  expect_equal(urps_demand_scalar("retail_clinic"), 1.0)
})

test_that("specialty is 'URPS' for all rows", {
  d <- urps_demand_scalars()
  expect_true(all(d$specialty == "URPS"))
})

test_that("all scalars are 1.0 (identity placeholder, not_calibrated)", {
  d <- urps_demand_scalars()
  expect_true(all(d$scalar == 1.0))
})

test_that("calibration_status is 'not_calibrated' for all rows", {
  d <- urps_demand_scalars()
  expect_true(all(d$calibration_status == "not_calibrated"))
})

test_that("calibration_source is populated (non-empty) for all rows", {
  d <- urps_demand_scalars()
  expect_true(all(nzchar(d$calibration_source)))
  # Verify the known calibration sources appear
  expect_true(any(grepl("NAMCS",    d$calibration_source)))
  expect_true(any(grepl("NIS",      d$calibration_source)))
  expect_true(any(grepl("NHAMCS",   d$calibration_source)))
})

test_that("scalar table carries source and formula_note attributes", {
  d <- urps_demand_scalars()
  expect_false(is.null(attr(d, "source")))
  expect_match(attr(d, "formula_note"), "scalar")
})

# ---- urps_demand_scalar (single-setting lookup) ------------------------------

test_that("urps_demand_scalar returns 1.0 for each valid setting", {
  for (s in c("office", "outpatient", "home_health", "inpatient", "ed"))
    expect_equal(urps_demand_scalar(s), 1.0, label = paste("scalar ==1 for", s))
})

test_that("unknown setting produces a hard error listing valid settings", {
  expect_error(urps_demand_scalar("clinic"),  "office")
  expect_error(urps_demand_scalar("OR"),      "inpatient")
})

test_that("non-string or NA setting produces a hard error", {
  expect_error(urps_demand_scalar(NA_character_), "single string")
  expect_error(urps_demand_scalar(1L),             "single string")
})
