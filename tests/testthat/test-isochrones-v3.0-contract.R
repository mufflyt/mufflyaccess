library(testthat)
library(mufflyaccess)

# Contract-version acceptance and rejection at the producer/consumer boundary.
# v3.0.0 is current; v2.x is retired (major 3 supported).

test_that("isochrones contract v3.0.0 is accepted", {
  expect_no_error(validate_urps_artifact(urps_fixture_dir("isochrones-v3.0.0")))
  expect_true(validate_urps_artifact(urps_fixture_dir("isochrones-v3.0.0")))
})

test_that("an unsupported major contract version fails closed", {
  path <- copy_urps_fixture("isochrones-v3.0.0")
  edit_manifest(path, function(x) {
    x$contract_version <- "4.0.0"
    x
  })
  expect_error(use_urps_artifact(path),
    regexp = "unsupported.*contract.*4\\.0\\.0", ignore.case = TRUE
  )
  expect_identical(getOption("mufflyaccess.urps_artifact_dir"), NULL)
})

test_that("the retired v2.x contract is no longer accepted as current", {
  path <- copy_urps_fixture("isochrones-v3.0.0")
  edit_manifest(path, function(x) {
    x$contract_version <- "2.1.0"
    x
  })
  edit_contract(path, function(x) {
    x$contract_version <- "2.1.0"
    x
  })
  expect_error(validate_urps_artifact(path),
    regexp = "unsupported.*contract.*2\\.1\\.0", ignore.case = TRUE
  )
})

test_that("a supported minor bump is accepted", {
  path <- copy_urps_fixture("isochrones-v3.0.0")
  edit_manifest(path, function(x) {
    x$contract_version <- "3.1.0"
    x
  })
  edit_contract(path, function(x) {
    x$contract_version <- "3.1.0"
    x
  })
  expect_no_error(validate_urps_artifact(path))
})

test_that("invalid semantic versions fail closed", {
  path <- copy_urps_fixture("isochrones-v3.0.0")
  edit_manifest(path, function(x) {
    x$contract_version <- "3.0"
    x
  }) # not x.y.z
  expect_error(validate_urps_artifact(path),
    regexp = "invalid.*version|contract",
    ignore.case = TRUE
  )
})

test_that("manifest and release-contract versions may not disagree", {
  path <- copy_urps_fixture("isochrones-v3.0.0")
  edit_manifest(path, function(x) {
    x$contract_version <- "3.2.0"
    x
  }) # contract stays 3.0.0
  expect_error(validate_urps_artifact(path), regexp = "disagree", ignore.case = TRUE)
})

test_that("legacy fused-geography contracts cannot masquerade as current", {
  path <- copy_urps_fixture("isochrones-v3.0.0")
  mutate_counts(path, function(x) {
    x$geographic_scope <- paste(x$measure, x$geography, sep = "_")
    x$measure <- NULL
    x$geography <- NULL
    x
  })
  refresh_fixture_hashes(path)
  expect_error(validate_urps_artifact(path),
    regexp = "measure.*geography|unsupported schema", ignore.case = TRUE
  )
})
