library(testthat)
library(mufflyaccess)
test_that("urps_provenance returns required metadata", {
  provenance <- urps_provenance()
  required_fields <- c(
    "artifact_version", "measure_years", "snapshot_date", "boards",
    "geographic_scope", "active_in_year_definition", "deduplication_rule",
    "source_sha256", "source_git_commit", "method_version", "package_version"
  )
  expect_type(provenance, "list")
  expect_true(all(required_fields %in% names(provenance)))
})

test_that("detailed = TRUE adds a verifiable provenance chain; default omits it", {
  expect_false("detail" %in% names(urps_provenance())) # non-breaking default
  d <- urps_provenance(detailed = TRUE)$detail
  expect_type(d, "list")
  expect_true(all(c(
    "source_files", "combined_source_sha256", "cohort_definition",
    "provider_snapshot", "output_files", "integrity",
    "geography_resolution_rule", "state_source_counts",
    "known_limitations"
  ) %in% names(d)))

  # source rosters are a tidy (name, path, sha256) frame with well-formed hashes
  expect_s3_class(d$source_files, "data.frame")
  expect_true(all(c("name", "path", "sha256") %in% names(d$source_files)))
  expect_true(all(grepl("^[0-9a-f]{64}$", d$source_files$sha256)))
  expect_match(d$combined_source_sha256, "^[0-9a-f]{64}$")

  # the provider snapshot reconstructs the served headline
  expect_equal(d$provider_snapshot$rows_national, 1339L)
  expect_equal(d$provider_snapshot$rows_active_2023, 1306L)

  # live integrity: the served CSV bytes match the manifest
  skip_if_not_installed("digest")
  expect_true(isTRUE(d$integrity$counts_csv_verified))
  expect_match(d$integrity$counts_csv_sha256_observed, "^[0-9a-f]{64}$")
})

test_that("detailed provenance verifies the provider parquet against the external release", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  d <- urps_provenance(detailed = TRUE)$detail
  expect_true(d$integrity$provider_parquet_present)
  skip_if_not_installed("digest")
  expect_true(isTRUE(d$integrity$counts_csv_verified))
  expect_true(isTRUE(d$integrity$provider_parquet_verified)) # bytes match the manifest hash
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
  expect_identical(
    provenance$package_version,
    as.character(utils::packageVersion("mufflyaccess"))
  )
})
