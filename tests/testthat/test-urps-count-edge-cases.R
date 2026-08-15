# Edge-case / contract coverage for urps_count() input validation and the
# measure/geography vocabulary. The happy path and the year / include_urology
# guards are covered in test-urps-count.R; this file pins the measure and
# geography validation, case-insensitive normalization, the roster_snapshot
# year-gating, and the details = TRUE record shape -- error surfaces that carry
# the public contract but were not otherwise asserted.

test_that("urps_count rejects an unknown or non-string measure", {
  expect_error(
    urps_count(2023, measure = "bogus"),
    "unknown measure|use one of"
  )
  expect_error(
    urps_count(2023, measure = 5),
    "measure.*single string|single string"
  )
  expect_error(
    urps_count(2023, measure = c("board_certified_active", "roster_snapshot")),
    "single string"
  )
})

test_that("urps_count rejects an unknown or non-string geography", {
  expect_error(
    urps_count(2023, geography = "mars"),
    "unknown geography|use one of"
  )
  expect_error(
    urps_count(2023, geography = 42),
    "geography.*single string|single string"
  )
})

test_that("measure and geography are case-insensitive and space-trimmed", {
  canonical <- urps_count(2023, "board_certified_active", "national", TRUE)
  expect_identical(urps_count(2023, "BOARD_CERTIFIED_ACTIVE", "national", TRUE), canonical)
  expect_identical(urps_count(2023, "board_certified_active", "NATIONAL", TRUE), canonical)
  expect_identical(
    urps_count(2023, "board_certified_active", " conus ", TRUE),
    urps_count(2023, "board_certified_active", "conus", TRUE)
  )
})

test_that("roster_snapshot is available only for its snapshot year", {
  # rejected for a board_certified_active year
  expect_error(
    urps_count(2023, measure = "roster_snapshot"),
    "roster_snapshot|not available"
  )
  # served for the snapshot year
  expect_equal(urps_count(2025, "roster_snapshot", "national", TRUE), 1339L)
  expect_equal(urps_count(2025, "roster_snapshot", "conus", TRUE), 1336L)
})

test_that("details = TRUE returns a provenance-carrying record whose count matches the scalar", {
  scalar <- urps_count(2023, "board_certified_active", "national", TRUE)
  rec <- urps_count(2023, "board_certified_active", "national", TRUE, details = TRUE)
  expect_type(rec, "list")
  expect_equal(rec$count, scalar)
  expect_true(all(c(
    "year", "measure", "geography", "include_urology",
    "contract_version", "artifact_source"
  ) %in% names(rec)))
  expect_identical(rec$measure, "board_certified_active")
  expect_true(isTRUE(rec$include_urology))
})
