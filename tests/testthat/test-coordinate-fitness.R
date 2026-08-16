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
    id = seq_len(n),
    coord_source = rep(c("rooftop", "address", "street_segment"), length.out = n),
    usable_for_travel_time = rep(TRUE, n),
    stringsAsFactors = FALSE
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
    "generate_isochrones\\(\\)",
    fixed = FALSE
  )
  # and it tells the caller what to do instead of just refusing
  expect_error(assert_travel_time_eligible(df), "report the exclusion")
})

test_that("centroid geocodes are refused whatever their casing or prefix", {
  for (src in c(
    "city_centroid", "CITY_CENTROID", "City Centroid",
    "zip_centroid", "county_centroid", "centroid"
  )) {
    df <- fit_rows(2)
    df$coord_source[2] <- src
    expect_error(assert_travel_time_eligible(df), "centroid geocode",
      info = paste("coord_source =", src)
    )
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
    data.frame(coord_source = character(0), usable_for_travel_time = logical(0))
  ))
})

# ==============================================================================
# The three-state contract on usable_for_travel_time
# ==============================================================================

test_that("TRUE is eligible", {
  df <- fit_rows(3)
  df$usable_for_travel_time <- TRUE
  expect_true(assert_travel_time_eligible(df))
})

test_that("FALSE is refused as a known-bad geocode", {
  df <- fit_rows(3)
  df$usable_for_travel_time[2] <- FALSE
  expect_error(assert_travel_time_eligible(df), "usable_for_travel_time = FALSE")
  expect_error(assert_travel_time_eligible(df), "1 row\\(s\\)")
})

test_that("NA is refused as UNKNOWN fitness, distinctly from a known-bad one", {
  df <- fit_rows(3)
  df$usable_for_travel_time[2] <- NA
  # refused at all -- "eligible unless proven otherwise" is the wrong default
  expect_error(assert_travel_time_eligible(df))
  # and refused with its OWN diagnostic, so a caller reporting an exclusion can
  # distinguish "never checked" from "checked and unfit"
  expect_error(assert_travel_time_eligible(df), "UNKNOWN geocode fitness")
  expect_error(assert_travel_time_eligible(df), "usable_for_travel_time = NA")
  expect_error(assert_travel_time_eligible(df), "1 row\\(s\\)")
  # the two states must not be confusable: the NA message must NOT read as the
  # known-bad one, or the caller cannot tell which exclusion they are reporting
  msg <- tryCatch(assert_travel_time_eligible(df),
    error = function(e) conditionMessage(e)
  )
  expect_false(grepl("usable_for_travel_time = FALSE", msg, fixed = TRUE))
})

test_that("unknown is reported before known-bad when both are present", {
  # A caller fixing this should learn about the unverified rows first: they are
  # the ones whose status is recoverable by checking, rather than by exclusion.
  df <- fit_rows(4)
  df$usable_for_travel_time[2] <- NA
  df$usable_for_travel_time[3] <- FALSE
  expect_error(assert_travel_time_eligible(df), "UNKNOWN geocode fitness")
})

test_that("the NA refusal counts every unknown row", {
  df <- fit_rows(5)
  df$usable_for_travel_time[c(1, 4, 5)] <- NA
  expect_error(assert_travel_time_eligible(df), "3 row\\(s\\) with UNKNOWN")
})

test_that("NA in coord_source still passes (asymmetry, pinned deliberately)", {
  # coord_source is a provenance label, not a fitness verdict: an absent label
  # is not a claim that the coordinate is unfit, and the fitness column is the
  # channel that carries that claim. Pinned so the asymmetry with
  # usable_for_travel_time is visible and any change is deliberate.
  df <- fit_rows(3)
  df$coord_source[2] <- NA_character_
  expect_true(assert_travel_time_eligible(df))
})
