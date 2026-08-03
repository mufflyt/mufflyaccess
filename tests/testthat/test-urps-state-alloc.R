library(testthat)

# urps_state_alloc.R: geographic distribution module tests.

# ---- version -----------------------------------------------------------------

test_that("URPS_STATE_ALLOC_VERSION is semver", {
  expect_match(URPS_STATE_ALLOC_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

# ---- urps_state_female_pop ---------------------------------------------------

test_that("urps_state_female_pop returns a 49-row data.frame", {
  df <- urps_state_female_pop()
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 49L)
})

test_that("urps_state_female_pop has required columns", {
  df <- urps_state_female_pop()
  expect_true(all(c("state_abbr", "state_fips", "female_pop", "female_share") %in% names(df)))
})

test_that("urps_state_female_pop female_pop sums to ACS2020_CONUS_FEMALE_POP", {
  df <- urps_state_female_pop()
  expect_equal(sum(df$female_pop), as.integer(ACS2020_CONUS_FEMALE_POP))
})

test_that("urps_state_female_pop female_share sums to 1", {
  df <- urps_state_female_pop()
  expect_equal(sum(df$female_share), 1.0, tolerance = 1e-6)
})

test_that("urps_state_female_pop state_abbr covers exactly CONUS_STATE_ABBR", {
  df <- urps_state_female_pop()
  expect_setequal(df$state_abbr, CONUS_STATE_ABBR)
})

test_that("urps_state_female_pop is sorted by state_fips", {
  df <- urps_state_female_pop()
  expect_equal(df$state_fips, sort(df$state_fips))
})

test_that("urps_state_female_pop carries a source attribute", {
  df <- urps_state_female_pop()
  expect_false(is.null(attr(df, "source")))
  expect_match(attr(df, "source"), "ACS")
})

# ---- urps_state_alloc_weights ------------------------------------------------

test_that("urps_state_alloc_weights returns a named numeric vector of length 49", {
  w <- urps_state_alloc_weights()
  expect_true(is.numeric(w))
  expect_equal(length(w), 49L)
  expect_false(is.null(names(w)))
})

test_that("urps_state_alloc_weights sums to 1", {
  w <- urps_state_alloc_weights()
  expect_equal(sum(w), 1.0, tolerance = 1e-6)
})

test_that("urps_state_alloc_weights covers exactly CONUS_STATE_ABBR", {
  w <- urps_state_alloc_weights()
  expect_setequal(names(w), CONUS_STATE_ABBR)
})

test_that("urps_state_alloc_weights CA has the largest weight", {
  w <- urps_state_alloc_weights()
  expect_equal(names(which.max(w)), "CA")
})

test_that("urps_state_alloc_weights unknown method errors", {
  expect_error(urps_state_alloc_weights("gdp"), "female_pop")
})

# ---- urps_allocate_national --------------------------------------------------

test_that("urps_allocate_national returns a 49-row data.frame", {
  df <- urps_allocate_national(1000L)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 49L)
})

test_that("urps_allocate_national has required columns", {
  df <- urps_allocate_national(1000L)
  expect_true(all(c("state_abbr", "state_fips", "n_allocated") %in% names(df)))
})

test_that("urps_allocate_national n_allocated sums to n exactly", {
  for (n in c(100L, 1000L, 1339L, 9999L)) {
    df <- urps_allocate_national(n)
    expect_equal(sum(df$n_allocated), n, label = paste("sum == n for n =", n))
  }
})

test_that("urps_allocate_national is sorted by state_fips", {
  df <- urps_allocate_national(1000L)
  expect_equal(df$state_fips, sort(df$state_fips))
})

test_that("urps_allocate_national n_allocated values are non-negative integers", {
  df <- urps_allocate_national(1000L)
  expect_true(is.integer(df$n_allocated))
  expect_true(all(df$n_allocated >= 0L))
})

test_that("urps_allocate_national rejects non-positive n", {
  expect_error(urps_allocate_national(0L),   "positive integer")
  expect_error(urps_allocate_national(-5L),  "positive integer")
})

test_that("urps_allocate_national rejects non-integer n", {
  expect_error(urps_allocate_national(1.5), "positive integer")
})

test_that("urps_allocate_national accepts custom weights summing to 1", {
  w <- urps_state_alloc_weights()
  df <- urps_allocate_national(500L, weights = w)
  expect_equal(sum(df$n_allocated), 500L)
})

test_that("urps_allocate_national rejects weights that don't sum to 1", {
  w <- urps_state_alloc_weights()
  w["CA"] <- w["CA"] + 0.1  # breaks sum
  expect_error(urps_allocate_national(1000L, weights = w), "sum to approximately 1")
})

test_that("urps_allocate_national rejects wrong-length weights", {
  w <- urps_state_alloc_weights()[1:10]
  expect_error(urps_allocate_national(1000L, weights = w), "length 49")
})

# ---- urps_state_entrant_shares -----------------------------------------------

test_that("urps_state_entrant_shares returns a named vector summing to 1", {
  shares <- urps_state_entrant_shares()
  expect_true(is.numeric(shares))
  expect_equal(length(shares), 49L)
  expect_equal(sum(shares), 1.0, tolerance = 1e-6)
})

test_that("urps_state_entrant_shares unknown demand_proxy errors", {
  expect_error(urps_state_entrant_shares("something_else"), "female_pop")
})
