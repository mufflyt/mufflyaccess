test_that("canonical scalar values are exactly as published", {
  expect_equal(PRIMARY_ACCESS_BAND_MIN, 60L)
  expect_equal(PRIMARY_ACCESS_BAND_SEC, 3600L)
  expect_identical(DENOMINATOR_CATEGORY, "total_female")
  expect_equal(TRACT_REACHED_COVERAGE_PCT, 50L)
  expect_equal(ACS2020_CONUS_FEMALE_POP, 164690617L)
})

test_that("derived values are consistent with their sources", {
  expect_identical(PRIMARY_ACCESS_BAND_SEC, PRIMARY_ACCESS_BAND_MIN * 60L)
  expect_true(PRIMARY_ACCESS_BAND_MIN %in% CANONICAL_BANDS)
  expect_equal(get_primary_access_band("sec"), 3600L)
  expect_equal(get_primary_access_band("min"), 60L)
  expect_error(get_primary_access_band("hours"))
})

test_that("CONUS_STATE_ABBR is derived from CONUS_STATE_FIPS and cannot drift", {
  expect_length(CONUS_STATE_FIPS, 49L)
  expect_length(CONUS_STATE_ABBR, 49L)
  expect_false(anyNA(CONUS_STATE_ABBR))
  expect_false(any(c("AK", "HI") %in% CONUS_STATE_ABBR))
  # the two representations describe the SAME 49 units
  expect_setequal(CONUS_STATE_ABBR, setdiff(c(datasets::state.abb, "DC"), c("AK", "HI")))
})

test_that("non-contiguous codes are disjoint from CONUS and complete", {
  expect_length(NON_CONTIGUOUS_FIPS, 7L)
  expect_false(any(NON_CONTIGUOUS_FIPS %in% CONUS_STATE_FIPS))
  expect_true(all(c("AK", "HI") %in% NON_CONTIGUOUS_CODES))
})

test_that("category label is not a race-prefixed member", {
  expect_false(grepl("^total_female_", DENOMINATOR_CATEGORY))
})

test_that("reached cut is a percent, band is minutes (unit sanity)", {
  expect_true(TRACT_REACHED_COVERAGE_PCT > 0L && TRACT_REACHED_COVERAGE_PCT <= 100L)
  expect_true(PRIMARY_ACCESS_BAND_MIN >= 1L && PRIMARY_ACCESS_BAND_MIN <= 24L * 60L)
})

test_that("ACS female pop carries provenance attributes", {
  a <- attributes(ACS2020_CONUS_FEMALE_POP)
  expect_true(all(c("vintage","table","scope","units") %in% names(a)))
  expect_match(a$table, "B01001_026")
  expect_match(a$scope, "contiguous", ignore.case = TRUE)
})
