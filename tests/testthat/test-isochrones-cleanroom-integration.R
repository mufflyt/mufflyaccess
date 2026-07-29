library(testthat)
library(mufflyaccess)

# Independent provider-to-count reconstruction + source precedence. The
# reconstruction uses simple, self-contained logic (NOT the isochrones counting
# helper) so it is a genuine cross-check. Skips when no parquet reader is present
# (the clean-room CI job installs arrow and runs these for real).

# v3.0.0 keys board_certified_active on urps_subspecialty_cert_year (training-
# accurate), NOT the primary certification_year. Reconstruct on that basis.
test_that("served 2023 national count reconstructs from provider rows", {
  path <- real_isochrones_artifact_path()
  providers <- read_provider_parquet(path)                 # skips if no reader
  cy <- providers$urps_subspecialty_cert_year
  expected <- sum(cy <= 2023L &
                    (is.na(providers$retirement_year) | providers$retirement_year > 2023L))
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  observed <- urps_count(2023, "board_certified_active", "national", TRUE)
  expect_equal(observed, expected)
  expect_equal(observed, 1306L)
})

test_that("served 2023 CONUS count reconstructs from provider rows", {
  path <- real_isochrones_artifact_path()
  providers <- read_provider_parquet(path)
  cy <- providers$urps_subspecialty_cert_year
  expected <- sum(cy <= 2023L &
                    (is.na(providers$retirement_year) | providers$retirement_year > 2023L) &
                    providers$is_conus)
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  expect_equal(urps_count(2023, "board_certified_active", "conus", TRUE), expected)
  expect_equal(urps_count(2023, "board_certified_active", "conus", TRUE), 1303L)
})

test_that("the active_2023 column agrees with the served count (basis check)", {
  path <- real_isochrones_artifact_path()
  providers <- read_provider_parquet(path)
  skip_if(!("active_2023" %in% names(providers)), "no active_2023 column")
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  expect_equal(sum(providers$active_2023), 1306L)
  expect_equal(sum(providers$active_2023 & providers$is_conus), 1303L)
})

test_that("roster snapshot equals the provider snapshot row count", {
  path <- real_isochrones_artifact_path()
  providers <- read_provider_parquet(path)
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  expect_equal(urps_count(2025, "roster_snapshot", "national", TRUE), nrow(providers))
  expect_equal(nrow(providers), 1339L)
})

test_that("33 URPS-subspecialty certs postdate 2023 (excluded from active)", {
  path <- real_isochrones_artifact_path()
  providers <- read_provider_parquet(path)
  expect_equal(sum(providers$urps_subspecialty_cert_year >= 2024L), 33L)
})

# ---- source-resolution precedence, with the authentic release ---------------

test_that("explicit real release overrides all implicit sources", {
  options(mufflyaccess.urps_artifact_dir = file.path(tempdir(), "invalid-artifact-a"))
  Sys.setenv(MUFFLYACCESS_URPS_ARTIFACT_DIR = file.path(tempdir(), "invalid-artifact-b"))
  on.exit({
    options(mufflyaccess.urps_artifact_dir = NULL)
    Sys.unsetenv("MUFFLYACCESS_URPS_ARTIFACT_DIR")
    reset_urps_artifact()
  }, add = TRUE)
  suppressMessages(use_urps_artifact(real_isochrones_artifact_path()))
  expect_equal(urps_provenance()$artifact_source, "external")
  expect_equal(urps_count(2023, "board_certified_active", "national", TRUE), 1306L)
})

test_that("a failed explicit call leaves an already-active real release intact", {
  suppressMessages(use_urps_artifact(real_isochrones_artifact_path()))
  on.exit(reset_urps_artifact(), add = TRUE)
  before <- getOption("mufflyaccess.urps_artifact_dir")
  expect_error(use_urps_artifact(file.path(tempdir(), "definitely-absent-zzz")))
  expect_identical(getOption("mufflyaccess.urps_artifact_dir"), before)
  expect_equal(urps_count(2023, "board_certified_active", "national", TRUE), 1306L)
})

test_that("strict mode errors before any count is returned", {
  options(mufflyaccess.urps_artifact_dir = file.path(tempdir(), "no-such-strict-dir"),
          mufflyaccess.urps_artifact_strict = TRUE)
  on.exit({
    options(mufflyaccess.urps_artifact_dir = NULL,
            mufflyaccess.urps_artifact_strict = NULL)
  }, add = TRUE)
  expect_error(urps_count(2023, "board_certified_active", "national", TRUE), "strict mode")
})
