library(testthat)
library(mufflyaccess)

# Source-handling readiness: bootstrap labeling, revealed fallback, strict mode,
# fail-closed adoption, and the release gate. (v2.1.0 numbers live in the
# dedicated isochrones-* test files.)

test_that("bundled provenance is honestly labeled a non-release bootstrap", {
  p <- urps_provenance()
  expect_identical(p$artifact_source, "bundled_bootstrap")
  expect_false(p$canonical_release)
  expect_false(p$suitable_for_release)
  expect_identical(p$contract_version, "2.1.0")   # the bundled numbers ARE v2.1.0
  expect_null(p$external_artifact_error)
})

test_that("an unusable option source warns, falls back, and reveals it", {
  bad <- file.path(tempdir(), "no_such_urps_dir_reveal")
  old <- getOption("mufflyaccess.urps_artifact_dir")
  on.exit(options(mufflyaccess.urps_artifact_dir = old), add = TRUE)
  options(mufflyaccess.urps_artifact_dir = bad)
  expect_warning(urps_provenance(), "bundled bootstrap")
  p <- suppressWarnings(urps_provenance())
  expect_identical(p$artifact_source, "bundled_bootstrap")
  expect_match(p$external_artifact_error, "does not exist")
  expect_equal(suppressWarnings(urps_count(2023L)), 1031L)     # still resolves
})

test_that("strict mode turns a bad option source into an error", {
  bad <- file.path(tempdir(), "no_such_urps_dir_strict")
  old  <- getOption("mufflyaccess.urps_artifact_dir")
  olds <- getOption("mufflyaccess.urps_artifact_strict")
  on.exit({
    options(mufflyaccess.urps_artifact_dir = old)
    options(mufflyaccess.urps_artifact_strict = olds)
  }, add = TRUE)
  options(mufflyaccess.urps_artifact_dir = bad, mufflyaccess.urps_artifact_strict = TRUE)
  expect_error(urps_count(2023L), "strict mode")
})

test_that("use_urps_artifact fails closed and leaves the source unchanged", {
  before <- getOption("mufflyaccess.urps_artifact_dir")
  expect_error(use_urps_artifact(file.path(tempdir(), "definitely_absent_xyz")))
  expect_identical(getOption("mufflyaccess.urps_artifact_dir"), before)
})

test_that("validate_urps_ssot(require_external) fails on the bundled bootstrap", {
  old <- getOption("mufflyaccess.urps_artifact_dir")
  on.exit(options(mufflyaccess.urps_artifact_dir = old), add = TRUE)
  options(mufflyaccess.urps_artifact_dir = NULL)
  expect_error(validate_urps_ssot(require_external = TRUE), "bootstrap|external")
})
