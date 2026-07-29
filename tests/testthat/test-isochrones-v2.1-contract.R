library(testthat)
library(mufflyaccess)

# Contract-version acceptance and rejection at the producer/consumer boundary.

test_that("isochrones contract v2.1.0 is accepted", {
  expect_no_error(validate_urps_artifact(urps_fixture_dir("isochrones-v2.1.0")))
  expect_true(validate_urps_artifact(urps_fixture_dir("isochrones-v2.1.0")))
})

test_that("unsupported major contract versions fail closed", {
  path <- copy_urps_fixture("isochrones-v2.1.0")
  edit_manifest(path, function(x) { x$contract_version <- "3.0.0"; x })
  expect_error(use_urps_artifact(path),
               regexp = "unsupported.*contract.*3\\.0\\.0", ignore.case = TRUE)
  expect_identical(getOption("mufflyaccess.urps_artifact_dir"), NULL)  # unchanged
})

test_that("a supported minor bump is accepted", {
  path <- copy_urps_fixture("isochrones-v2.1.0")
  edit_manifest(path, function(x) { x$contract_version <- "2.2.0"; x })
  edit_contract(path, function(x) { x$contract_version <- "2.2.0"; x })
  expect_no_error(validate_urps_artifact(path))
})

test_that("missing / invalid semantic versions fail closed", {
  path <- copy_urps_fixture("isochrones-v2.1.0")
  edit_manifest(path, function(x) { x$contract_version <- "2.1"; x })   # not x.y.z
  expect_error(validate_urps_artifact(path), regexp = "invalid.*version|contract",
               ignore.case = TRUE)
})

test_that("manifest and release-contract versions may not disagree", {
  path <- copy_urps_fixture("isochrones-v2.1.0")
  edit_manifest(path, function(x) { x$contract_version <- "2.0.0"; x })  # contract stays 2.1.0
  expect_error(validate_urps_artifact(path), regexp = "disagree", ignore.case = TRUE)
})

test_that("legacy fused-geography contracts cannot masquerade as v2.1", {
  path <- copy_urps_fixture("isochrones-v2.1.0")
  mutate_counts(path, function(x) {
    x$geographic_scope <- paste(x$measure, x$geography, sep = "_")
    x$measure <- NULL
    x$geography <- NULL
    x
  })
  refresh_fixture_hashes(path)
  expect_error(validate_urps_artifact(path),
               regexp = "measure.*geography|unsupported schema", ignore.case = TRUE)
})
