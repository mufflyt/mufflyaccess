library(testthat)
library(mufflyaccess)

# The full semantic headline matrix against the real v2.1.0 release.

test_that("real isochrones v2.1 release serves canonical counts", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)

  expect_equal(urps_count(2023, "board_certified_active", "national", FALSE), 1031L)
  expect_equal(urps_count(2023, "board_certified_active", "national", TRUE),  1332L)
  expect_equal(urps_count(2023, "board_certified_active", "conus",    FALSE), 1030L)
  expect_equal(urps_count(2023, "board_certified_active", "conus",    TRUE),  1329L)
  expect_equal(urps_count(2025, "roster_snapshot",        "national", TRUE),  1339L)
  expect_equal(urps_count(2025, "roster_snapshot",        "conus",    TRUE),  1336L)
  expect_equal(urps_count(2025, "roster_snapshot",        "national", FALSE), 1031L)
  expect_equal(urps_count(2025, "roster_snapshot",        "conus",    FALSE), 1030L)
})

test_that("urology increments retain their intended meaning", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)

  # 2023 active: +301 (NOT the old 308)
  expect_equal(
    urps_count(2023, "board_certified_active", "national", TRUE) -
      urps_count(2023, "board_certified_active", "national", FALSE), 301L)
  # 2025 roster snapshot: +308
  expect_equal(
    urps_count(2025, "roster_snapshot", "national", TRUE) -
      urps_count(2025, "roster_snapshot", "national", FALSE), 308L)
})

test_that("national - conus differences are the real 3-provider gap", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)

  expect_equal(
    urps_count(2023, "board_certified_active", "national", TRUE) -
      urps_count(2023, "board_certified_active", "conus", TRUE), 3L)
  expect_equal(
    urps_count(2025, "roster_snapshot", "national", TRUE) -
      urps_count(2025, "roster_snapshot", "conus", TRUE), 3L)
})
