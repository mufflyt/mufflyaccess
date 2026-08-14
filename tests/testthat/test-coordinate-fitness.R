# assert_travel_time_eligible() -- the routing-fitness guard.
#
# This was the only export in the package with no test naming it. The guard
# exists because "whoever happened to be geocoded" silently redefined a
# denominator once before (the midwifery roster: 28,512 of 50,556, and the
# missingness was invisible precisely because the missing were never counted).
# A guard against silent exclusion that is itself untested is the same failure
# one level up.
#
# The coord_source vocabulary below is the real one from isochrones --
# "city_centroid", "rooftop", "address", "street_segment", "exact" -- rather
# than invented values, so these fixtures match what the guard actually meets.

fit_rows <- function(n = 3) {
  data.frame(
    id                    = seq_len(n),
    coord_source          = rep(c("rooftop", "address", "street_segment"), length.out = n),
    usable_for_travel_time = rep(TRUE, n),
    stringsAsFactors      = FALSE
  )
}

test_that("fit coordinates pass and the return is an invisible TRUE", {
  df <- fit_rows()
  expect_true(assert_travel_time_eligible(df))
  expect_invisible(assert_travel_time_eligible(df))
  expect_silent(assert_travel_time_eligible(df))
})

test_that("a data frame carrying neither column passes", {
  # Documented behaviour: the guard constrains what it can see and does not
  # invent a verdict about what it cannot, so it is safe on inputs predating
  # the convention.
  expect_true(assert_travel_time_eligible(data.frame(id = 1:3, lat = 1:3, lon = 4:6)))
  expect_true(assert_travel_time_eligible(data.frame()))
})

test_that("usable_for_travel_time = FALSE is refused, with the count and context", {
  df <- fit_rows(4)
  df$usable_for_travel_time[c(2, 4)] <- FALSE
  expect_error(assert_travel_time_eligible(df), "2 row\\(s\\)")
  expect_error(assert_travel_time_eligible(df), "usable_for_travel_time = FALSE")
  # the context label reaches the message, so the caller is identifiable
  expect_error(assert_travel_time_eligible(df, context = "generate_isochrones()"),
               "generate_isochrones\\(\\)", fixed = FALSE)
  # and it tells the caller what to do instead of just refusing
  expect_error(assert_travel_time_eligible(df), "report the exclusion")
})

test_that("centroid geocodes are refused whatever their casing or prefix", {
  for (src in c("city_centroid", "CITY_CENTROID", "City Centroid",
                "zip_centroid", "county_centroid", "centroid")) {
    df <- fit_rows(2)
    df$coord_source[2] <- src
    expect_error(assert_travel_time_eligible(df), "centroid geocode",
                 info = paste("coord_source =", src))
  }
})

test_that("non-centroid sources are not refused by a substring accident", {
  # guard against a looser match catching legitimate values
  df <- fit_rows(3)
  df$coord_source <- c("rooftop", "address_core", "exact_full")
  expect_true(assert_travel_time_eligible(df))
})

test_that("the refusal counts every offending row, not just the first", {
  df <- fit_rows(5)
  df$coord_source[c(1, 3, 5)] <- "city_centroid"
  expect_error(assert_travel_time_eligible(df), "3 centroid geocode")
})

test_that("the usable flag is checked before coord_source", {
  # Both signals bad: the message must name the flag, so the caller fixes the
  # more fundamental problem first rather than chasing the geocode source.
  df <- fit_rows(2)
  df$usable_for_travel_time <- FALSE
  df$coord_source <- "city_centroid"
  expect_error(assert_travel_time_eligible(df), "usable_for_travel_time = FALSE")
})

test_that("a non-data-frame input is refused", {
  expect_error(assert_travel_time_eligible(list(a = 1)), "must be a data frame")
  expect_error(assert_travel_time_eligible(NULL), "must be a data frame")
  expect_error(assert_travel_time_eligible(1:3), "must be a data frame")
})

test_that("an sf-style object (data.frame subclass) is accepted", {
  df <- fit_rows()
  class(df) <- c("sf", "data.frame")
  expect_true(assert_travel_time_eligible(df))
})

test_that("zero rows pass", {
  expect_true(assert_travel_time_eligible(fit_rows(0)))
  expect_true(assert_travel_time_eligible(
    data.frame(coord_source = character(0), usable_for_travel_time = logical(0))))
})

test_that("NA in usable_for_travel_time currently PASSES (pinned, not endorsed)", {
  # which(!NA) is integer(0), so a row whose fitness is UNKNOWN is treated as
  # fit. Pinned here so the behaviour is visible and any change is deliberate.
  # Whether unknown fitness should instead be loud is a design question: it is
  # the one path through this guard where a row can go unchecked in silence,
  # which is the failure mode the guard exists to prevent.
  df <- fit_rows(3)
  df$usable_for_travel_time[2] <- NA
  expect_true(assert_travel_time_eligible(df))

  # NA in coord_source likewise does not match "centroid" and so passes.
  df2 <- fit_rows(3)
  df2$coord_source[2] <- NA_character_
  expect_true(assert_travel_time_eligible(df2))
})
