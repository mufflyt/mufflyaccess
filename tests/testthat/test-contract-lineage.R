library(testthat)
library(mufflyaccess)

# Contract lineage + retired-cell protection. 1332/1329 are RETIRED v2.1.0
# cells (primary-cert basis); they may appear ONLY as retired values, never as
# the current 2023 active count.

test_that("urps_lineage records current 3.0.0 and retired 2.1.0 cells", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  lin <- urps_lineage()
  expect_true(all(c("contract_version", "national_active", "conus_active", "status") %in% names(lin)))

  cur <- lin[lin$status == "current", ]
  expect_equal(cur$contract_version, "3.0.0")
  expect_equal(cur$national_active, 1306L)
  expect_equal(cur$conus_active, 1303L)

  ret <- lin[lin$status == "retired", ]
  expect_equal(ret$contract_version, "2.1.0")
  expect_equal(ret$national_active, 1332L)
  expect_equal(ret$conus_active, 1329L)
})

test_that("retired values are exposed and are exactly 1332/1329", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  expect_setequal(urps_retired_values(), c(1332L, 1329L))
})

test_that("no current API call returns a retired value", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  retired <- urps_retired_values()
  current <- c(
    urps_count(2023, "board_certified_active", "national", TRUE),
    urps_count(2023, "board_certified_active", "conus", TRUE),
    urps_count(2023, "board_certified_active", "national", FALSE),
    urps_count(2023, "board_certified_active", "conus", FALSE)
  )
  expect_length(intersect(current, retired), 0)
})

test_that("provenance exposes the exact isochrones source wording", {
  path <- real_isochrones_artifact_path()
  manifest <- read_isochrones_manifest(path)
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  p <- urps_provenance()
  expect_identical(p$source_description, manifest$source_description) # verbatim, no drift
  expect_match(p$source_description, "did not supply, license, or endorse", fixed = TRUE)
  expect_false(is.null(p$retired_cells))
})
