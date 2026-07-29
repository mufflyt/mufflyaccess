library(testthat)
library(mufflyaccess)

test_that("bundled provenance is honestly labeled a non-release bootstrap", {
  p <- urps_provenance()
  expect_identical(p$artifact_source, "bundled_bootstrap")
  expect_false(p$canonical_release)
  expect_false(p$suitable_for_release)
  expect_identical(p$contract_version, "1.0.0")
  expect_true(is.na(p$external_artifact_error))
})

test_that("an unusable option source warns, falls back, and reveals it", {
  bad <- file.path(tempdir(), "no_such_urps_dir_reveal")
  old <- getOption("mufflyaccess.urps_artifact_dir")
  on.exit(options(mufflyaccess.urps_artifact_dir = old), add = TRUE)
  options(mufflyaccess.urps_artifact_dir = bad)
  expect_warning(p <- urps_provenance(), "bundled bootstrap")
  expect_identical(suppressWarnings(urps_provenance())$artifact_source, "bundled_bootstrap")
  expect_match(suppressWarnings(urps_provenance())$external_artifact_error, "does not exist")
  # counts still resolve from the bootstrap
  expect_equal(suppressWarnings(urps_count(2023L)), 1031L)
})

test_that("strict mode turns a bad option source into an error", {
  bad <- file.path(tempdir(), "no_such_urps_dir_strict")
  old <- getOption("mufflyaccess.urps_artifact_dir")
  olds <- getOption("mufflyaccess.urps_artifact_strict")
  on.exit({
    options(mufflyaccess.urps_artifact_dir = old)
    options(mufflyaccess.urps_artifact_strict = olds)
  }, add = TRUE)
  options(mufflyaccess.urps_artifact_dir = bad,
          mufflyaccess.urps_artifact_strict = TRUE)
  expect_error(urps_count(2023L), "strict mode")
})

test_that("use_urps_artifact fails closed and leaves the source unchanged", {
  before <- getOption("mufflyaccess.urps_artifact_dir")
  expect_error(use_urps_artifact(file.path(tempdir(), "definitely_absent_xyz")))
  expect_identical(getOption("mufflyaccess.urps_artifact_dir"), before)
})

test_that("incomplete controls unavailable year/cohort handling", {
  expect_error(urps_count(2013L, include_urology = TRUE), "not available|2023")
  expect_true(is.na(urps_count(2013L, include_urology = TRUE, incomplete = "na")))
  expect_type(urps_count(2013L, include_urology = TRUE, incomplete = "na"), "integer")
})

test_that("geography assertion matches the served scope and rejects mismatches", {
  expect_equal(urps_count(2023L, geography = "CONUS"), 1031L)   # bundled scope
  expect_error(urps_count(2023L, geography = "state"), "not available|re-project")
})

test_that("wide table exposes explicit value_status columns", {
  w <- urps_counts()
  expect_true(all(c("abu_net_new_status", "combined_active_status") %in% names(w)))
  expect_identical(w$abu_net_new_status[w$year == 2013L], "unavailable")
  expect_identical(w$abu_net_new_status[w$year == 2023L], "snapshot")
  expect_identical(w$combined_active_status[w$year == 2023L], "derived")
})

test_that("validate_urps_ssot(require_external) fails on the bundled bootstrap", {
  old <- getOption("mufflyaccess.urps_artifact_dir")
  on.exit(options(mufflyaccess.urps_artifact_dir = old), add = TRUE)
  options(mufflyaccess.urps_artifact_dir = NULL)
  expect_error(validate_urps_ssot(require_external = TRUE), "bootstrap")
})
