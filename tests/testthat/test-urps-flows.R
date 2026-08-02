# Contract 3.0.0 corrective interface (0.7.1): retirement ascertainment + entrants.
library(testthat)

test_that("retirement is not_ascertained and served as NA, never a placeholder 0", {
  skip_if_not(exists("urps_retirement_status"))
  expect_identical(urps_retirement_status(), "not_ascertained")
  long <- urps_counts_long()
  expect_true("retirement_status" %in% names(long))
  expect_true(all(long$retirement_status == "not_ascertained"))
  # the artifact ships 0; the served view must be NA (never 0)
  expect_true(all(is.na(long$n_retired)))
  expect_false(any(long$n_retired == 0L, na.rm = TRUE))
})

test_that("the guard fails loudly rather than letting unknown retirement become zero", {
  skip_if_not(exists("urps_require_retirement_ascertained"))
  expect_error(urps_require_retirement_ascertained(), "NA, never 0|not.*served|Do NOT substitute 0")
})

test_that("the placeholder guard rejects a concrete count when status is not observed", {
  skip_if_not(exists(".urps_guard_no_placeholder",
                     where = asNamespace("mufflyaccess"), inherits = FALSE))
  g <- get(".urps_guard_no_placeholder", envir = asNamespace("mufflyaccess"))
  expect_error(g(0L, "not_ascertained", "retirement"), "must remain NA, never 0")
  expect_error(g(c(NA, 5L), "partially_observed"), "must remain NA, never 0")
  expect_silent(g(0L, "observed"))          # observed 0 is a real fact, allowed
  expect_silent(g(NA_integer_, "not_ascertained"))  # NA is the correct unavailable value
})

test_that("retirement status is always a valid observed-fact status (never modeled)", {
  skip_if_not(exists("urps_retirement_status"))
  expect_true(urps_retirement_status() %in%
                c("observed", "partially_observed", "not_ascertained"))
})

test_that("entrant counts derive from subspecialty cert year and reconcile to the stock", {
  skip_if_not(exists("urps_entry_counts"))
  ec <- urps_entry_counts("board_certified_active", "national")
  expect_setequal(ec$year, 2013:2023)
  expect_true(all(ec$basis == "urps_subspecialty_cert_year"))
  expect_true(ec$first_year_is_founding_bucket[ec$year == 2013])
  # entrants telescope back to the active stock (no attrition term in the build-up)
  st  <- urps_counts("board_certified_active", "national")
  st  <- st[order(st$year), ]
  expect_equal(cumsum(ec$abog_entrants[order(ec$year)]), st$abog_active)
  expect_equal(cumsum(ec$combined_entrants[order(ec$year)]), st$combined_active)
  # 2013 founding bucket = 2013 active stock
  expect_equal(urps_entrants(2013, "national", include_urology = FALSE), 471L)
  expect_equal(urps_entrants(2013, "national", include_urology = TRUE),  655L)
  # entrants are NOT fellowship graduations -- documented interpretation carried
  expect_match(ec$interpretation[1], "NOT fellowship graduation")
})

test_that("entrants are labeled entry-into-stock, not net growth or graduation", {
  skip_if_not(exists("urps_entry_counts"))
  ec <- urps_entry_counts()
  expect_false(any(grepl("graduat", tolower(ec$interpretation)) &
                   !grepl("not fellowship graduat", tolower(ec$interpretation))))
})
