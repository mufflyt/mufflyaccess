library(testthat)
library(mufflyaccess)

# urps_projection() serves the published RESULT. These tests check that it stays
# internally consistent and reconciles with the other things the package serves,
# rather than re-asserting the numbers it is made of -- a test that just repeats
# the artifact proves only that the file was read.

test_that("the projection starts from the published active count", {
  p <- urps_projection()
  expect_equal(p$baseline_headcount,
               urps_count(2023L, "board_certified_active", "national", TRUE))
  expect_equal(p$baseline_headcount, 1306L)   # NOT 1339 (2025 roster snapshot)
})

test_that("the projection starts from the cohort urps_active_ages() serves", {
  # The projection and the distribution it projects must describe one cohort.
  expect_equal(urps_projection()$baseline_headcount,
               sum(urps_active_ages()$n_active))
})

test_that("replacement ratio is exactly entrants over exits", {
  p <- urps_projection()
  expect_equal(p$replacement_ratio, p$annual_entrants / p$mean_annual_exits,
               tolerance = 1e-9)
})

test_that("the interval brackets the point estimate", {
  p <- urps_projection()
  expect_lte(p$lower_95, p$projected_headcount)
  expect_gte(p$upper_95, p$projected_headcount)
  expect_gt(p$sd, 0)
})

test_that("the horizon follows the baseline and the counts are non-negative", {
  p <- urps_projection()
  expect_gt(p$horizon_year, p$baseline_year)
  expect_gt(p$baseline_headcount, 0)
  expect_gt(p$projected_headcount, 0)
  expect_gt(p$annual_entrants, 0)
  expect_gt(p$mean_annual_exits, 0)
})

test_that("the entry ramp defers growth rather than reversing it", {
  # Ramping delays entrants, so it must land below the immediate-entry figure
  # but still above the baseline: it is a timing sensitivity, not a decline.
  p <- urps_projection()
  expect_lt(p$projected_headcount_ramped, p$projected_headcount)
  expect_gt(p$projected_headcount_ramped, p$baseline_headcount)
})

test_that("growth is consistent with entrants exceeding exits", {
  # A replacement ratio above 1 must imply a workforce that grows.
  p <- urps_projection()
  expect_gt(p$replacement_ratio, 1)
  expect_gt(p$projected_headcount, p$baseline_headcount)
})

test_that("the result is one row with the contract's vocabulary", {
  p <- urps_projection()
  expect_equal(nrow(p), 1L)
  expect_true(p$certification_pathway %in% c("ABOG", "ABU_NET_NEW", "ABOG_PLUS_ABU"))
  expect_true(p$geography_type %in% c("national", "conus"))
  expect_equal(p$specialty, "URPS")
  expect_type(p$baseline_headcount, "integer")
})

test_that("unpublished slices fail loud and say what is available", {
  expect_error(urps_projection(scenario = "no_such_scenario"), "no published projection")
  expect_error(urps_projection(scenario = "no_such_scenario"), "Published:")
  expect_error(urps_projection(pathway = "ABOG"), "no published projection")
  expect_error(urps_projection(geography = "state"), "unknown geography")
  expect_error(urps_projection(scenario = c("a", "b")), "single string")
})

test_that("scenario and geography are case-insensitive", {
  expect_equal(urps_projection("BASELINE"), urps_projection("baseline"))
  expect_equal(urps_projection(geography = "National"), urps_projection())
})
