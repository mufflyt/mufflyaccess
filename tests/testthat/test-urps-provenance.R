library(testthat)
library(mufflyaccess)
test_that("urps_provenance returns required metadata", {
  provenance <- urps_provenance()
  required_fields <- c("artifact_version","measure_years","snapshot_date","boards",
    "geographic_scope","active_in_year_definition","deduplication_rule",
    "source_sha256","source_git_commit","method_version","package_version")
  expect_type(provenance, "list")
  expect_true(all(required_fields %in% names(provenance)))
})
test_that("provenance distinguishes all temporal concepts", {
  provenance <- urps_provenance()
  expect_setequal(provenance$measure_years, 2013:2023)
  expect_s3_class(provenance$snapshot_date, "Date")
  expect_false(identical(provenance$snapshot_date, provenance$measure_years))
})
test_that("source identifiers have valid formats", {
  provenance <- urps_provenance()
  expect_match(provenance$source_sha256, "^[0-9a-f]{64}$")
  expect_match(provenance$source_git_commit, "^[0-9a-f]{40}$")
})
test_that("package version is the installed package version", {
  provenance <- urps_provenance()
  expect_identical(provenance$package_version,
                   as.character(utils::packageVersion("mufflyaccess")))
})
