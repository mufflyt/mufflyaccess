library(testthat)
library(mufflyaccess)

# Measure/geography/year semantics: 1306 and 1339 are NOT interchangeable, and
# mufflyaccess selects published cells rather than inferring or re-projecting.

test_that("2023 active and 2025 roster snapshot are not interchangeable", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)

  active_2023   <- urps_count(2023, "board_certified_active", "national", TRUE)
  snapshot_2025 <- urps_count(2025, "roster_snapshot",        "national", TRUE)
  expect_equal(active_2023, 1306L)
  expect_equal(snapshot_2025, 1339L)
  expect_equal(snapshot_2025 - active_2023, 33L)     # 33 URPS-subspecialty certs postdate 2023
  expect_false(identical(active_2023, snapshot_2025))
})

test_that("snapshot measure cannot be relabeled as 2023", {
  expect_error(urps_count(2023, "roster_snapshot", "national", TRUE),
               regexp = "snapshot.*2025|not available", ignore.case = TRUE)
})

test_that("board-certified series does not extend beyond its declared window", {
  expect_error(urps_count(2025, "board_certified_active", "national", TRUE),
               regexp = "unsupported.*year|2013.*2023", ignore.case = TRUE)
  expect_error(urps_count(2012, "board_certified_active", "national", TRUE),
               regexp = "unsupported.*year|2013.*2023", ignore.case = TRUE)
})

test_that("geography is normalized but unknown values fail loud", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  # normalization: uppercase resolves to the lowercase stored cell
  expect_equal(urps_count(2023, "board_certified_active", "CONUS", TRUE), 1303L)
  expect_equal(urps_count(2023, "board_certified_active", "National", FALSE), 1027L)
  # unknown geography / measure are rejected
  expect_error(urps_count(2023, "board_certified_active", "state", TRUE), "geography")
  expect_error(urps_count(2023, "national_active", "national", TRUE), "measure")
})

test_that("argument validation stays strict", {
  expect_error(urps_count(year = c(2022L, 2023L)), "single")
  expect_error(urps_count(year = NA_integer_), "year")
  expect_error(urps_count(year = "2023"), "integer|numeric|year")
  expect_error(urps_count(2023, "board_certified_active", "national", NA), "include_urology")
  expect_error(urps_count(2023, "board_certified_active", "national", c(TRUE, FALSE)),
               "include_urology|single")
  expect_error(urps_count(2023, "board_certified_active", "national", 1), "logical")
})

test_that("details mode carries context so no bare 1306 escapes", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  x <- urps_count(2023, "board_certified_active", "national", TRUE, details = TRUE)
  expect_equal(x$count, 1306L)
  expect_equal(x$measure, "board_certified_active")
  expect_equal(x$geography, "national")
  expect_equal(x$year, 2023L)
  expect_equal(x$contract_version, "3.0.0")
  expect_equal(x$artifact_source, "external")
  expect_true(x$canonical_release)
  expect_equal(x$value_status, "derived")
})

test_that("incomplete controls a genuinely absent published cell", {
  path <- copy_real_isochrones_artifact()
  # drop only the conus/2023 combined cell, then serve via the option resolver
  mutate_counts(path, function(d)
    d[!(d$year == 2023 & d$measure == "board_certified_active" &
        d$geography == "conus" & d$board_pathway == "ABOG_PLUS_ABU"), , drop = FALSE])
  old <- getOption("mufflyaccess.urps_artifact_dir")
  on.exit(options(mufflyaccess.urps_artifact_dir = old), add = TRUE)
  options(mufflyaccess.urps_artifact_dir = path)          # resolver path (no validation)
  expect_error(urps_count(2023, "board_certified_active", "conus", TRUE), "no published")
  expect_true(is.na(urps_count(2023, "board_certified_active", "conus", TRUE, incomplete = "na")))
})

test_that("wide slice reconciles and carries explicit status columns", {
  path <- real_isochrones_artifact_path()
  suppressMessages(use_urps_artifact(path))
  on.exit(reset_urps_artifact(), add = TRUE)
  w <- urps_counts("board_certified_active", "national")
  expect_setequal(w$year, 2013:2023)
  expect_equal(w$combined_active, w$abog_active + w$abu_net_new)
  expect_equal(w$combined_active[w$year == 2023L], 1306L)
  expect_true(all(w$abu_net_new_status == "observed"))
  expect_true(all(w$combined_active_status == "derived"))
})
