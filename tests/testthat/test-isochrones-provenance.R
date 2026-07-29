library(testthat)
library(mufflyaccess)

# Provenance round-trip: manifest -> urps_provenance(), plus release gates.

test_that("real artifact hashes and source commit are exposed unchanged", {
  path <- real_isochrones_artifact_path()
  manifest <- read_isochrones_manifest(path)
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)

  p <- urps_provenance()
  expect_equal(p$artifact_source, "external")
  expect_true(p$canonical_release)
  expect_true(p$suitable_for_release)
  expect_equal(p$contract_version, "2.1.0")
  expect_equal(p$artifact_version, "2.1.0")
  expect_equal(p$source_git_commit, manifest$git_commit)
  expect_match(p$source_git_commit, "^[0-9a-f]{40}$")
  expect_null(p$external_artifact_error)
})

test_that("temporal concepts stay distinct in provenance", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  p <- urps_provenance()
  expect_setequal(p$measure_years, 2013:2023)
  expect_s3_class(p$snapshot_date, "Date")
  expect_equal(p$roster_reflects_certifications_through, 2025L)
  expect_setequal(p$measures, c("board_certified_active", "roster_snapshot"))
  expect_setequal(p$geographies, c("national", "conus"))
})

test_that("git commit semantics are recorded", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  p <- urps_provenance()
  expect_type(p$git_commit_semantics, "character")
  expect_true(nzchar(p$git_commit_semantics))
})

test_that("the release gate passes for the real release and fails for the bootstrap", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  expect_true(validate_urps_ssot(require_external = TRUE))
  expect_true(validate_urps_ssot(require_external = TRUE, require_canonical = TRUE,
                                 require_contract_version = "2.1.0"))
  manifest <- read_isochrones_manifest(path)
  expect_true(validate_urps_ssot(require_external = TRUE,
                                 require_source_git_commit = manifest$git_commit))
  # a wrong pin fails
  expect_error(validate_urps_ssot(require_external = TRUE,
                                  require_source_git_commit = paste(rep("0", 40), collapse = "")),
               "git commit")
  reset_urps_artifact()
  expect_error(validate_urps_ssot(require_external = TRUE),
               regexp = "external|canonical|bootstrap", ignore.case = TRUE)
})
