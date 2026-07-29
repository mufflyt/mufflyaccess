library(testthat)
library(mufflyaccess)

# The full semantic headline matrix against the real v3.0.0 release.

test_that("real isochrones v3.0 release serves canonical counts", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)

  expect_equal(urps_count(2023, "board_certified_active", "national", FALSE), 1027L)
  expect_equal(urps_count(2023, "board_certified_active", "national", TRUE),  1306L)
  expect_equal(urps_count(2023, "board_certified_active", "conus",    FALSE), 1026L)
  expect_equal(urps_count(2023, "board_certified_active", "conus",    TRUE),  1303L)
  expect_equal(urps_count(2025, "roster_snapshot",        "national", TRUE),  1339L)
  expect_equal(urps_count(2025, "roster_snapshot",        "conus",    TRUE),  1336L)
  expect_equal(urps_count(2025, "roster_snapshot",        "national", FALSE), 1031L)
  expect_equal(urps_count(2025, "roster_snapshot",        "conus",    FALSE), 1030L)
})

test_that("urology increments retain their intended meaning", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)

  # 2023 active: +279 (URPS-subspecialty-cert basis)
  expect_equal(
    urps_count(2023, "board_certified_active", "national", TRUE) -
      urps_count(2023, "board_certified_active", "national", FALSE), 279L)
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

test_that("retired v2.1.0 cells are never served as current", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  current <- urps_count(2023, "board_certified_active", "national", TRUE)
  expect_false(current %in% c(1332L, 1329L))   # retired primary-cert-basis values
  expect_true(all(urps_retired_values() %in% c(1332L, 1329L)))
})
