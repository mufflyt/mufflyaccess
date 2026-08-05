library(testthat)
library(mufflyaccess)

# ==============================================================================
# Boundary Value Analysis. For every bounded input we probe the four classic
# points -- just-below / on / on / just-above the edge -- and, for each validator
# comparison, whether the boundary itself is INCLUSIVE (<=) or EXCLUSIVE (<).
# ==============================================================================

# ---- urps_count(): the measure year-windows ---------------------------------
# board_certified_active is defined 2013-2023; roster_snapshot is 2025 only.

test_that("board_certified_active year window: 2012 | 2013 .. 2023 | 2024", {
  expect_error(urps_count(2012, "board_certified_active", "national", TRUE), "2013")   # min - 1
  expect_type(urps_count(2013, "board_certified_active", "national", TRUE), "integer") # min
  expect_type(urps_count(2023, "board_certified_active", "national", TRUE), "integer") # max
  expect_error(urps_count(2024, "board_certified_active", "national", TRUE),
               "unsupported year|2013")                                                # max + 1
  # the max cell is the canonical 1306
  expect_equal(urps_count(2023, "board_certified_active", "national", TRUE), 1306L)
})

test_that("roster_snapshot year window: 2024 | 2025 | 2026 (single-point window)", {
  expect_error(urps_count(2024, "roster_snapshot", "national", TRUE), "2025")          # min - 1
  expect_equal(urps_count(2025, "roster_snapshot", "national", TRUE), 1339L)           # the point
  expect_error(urps_count(2026, "roster_snapshot", "national", TRUE), "2025")          # max + 1
})

test_that("the two measures reject each other's boundary years", {
  # 2025 is valid for roster_snapshot but one past the bca window
  expect_error(urps_count(2025, "board_certified_active"), "2013-2023|unsupported")
  # 2023 is the bca max but not the roster year
  expect_error(urps_count(2023, "roster_snapshot"), "2025")
})

# ---- validate_urps_projection(): numeric edges ------------------------------

base <- function(...) {
  d <- data.frame(year = 2025L, scenario_id = "baseline", specialty = "URPS",
    certification_pathway = "ABOG_PLUS_ABU", geography_type = "national",
    geography_id = "US", supply_headcount = 1000, stringsAsFactors = FALSE)
  mods <- list(...); for (nm in names(mods)) d[[nm]] <- mods[[nm]]
  d
}

test_that("supply_headcount non-negativity boundary: 0 passes, just-below fails", {
  expect_true(validate_urps_projection(base(supply_headcount = 0)))        # on the edge
  expect_error(validate_urps_projection(base(supply_headcount = -1e-9)),   # just below
               "non-negative")
})

test_that("95% bounds bracket INCLUSIVELY (lower<=point<=upper)", {
  sh <- 1000
  expect_true(validate_urps_projection(base(lower_95 = sh, upper_95 = sh)))       # both on the point
  expect_true(validate_urps_projection(base(lower_95 = sh - 1e-9, upper_95 = sh + 1e-9)))
  expect_error(validate_urps_projection(base(lower_95 = sh + 1e-6, upper_95 = sh + 5)),  # lower just above
               "bounds do not bracket")
  expect_error(validate_urps_projection(base(lower_95 = sh - 5, upper_95 = sh - 1e-6)),  # upper just below
               "bounds do not bracket")
})

test_that("supply_clinical_fte bound [0, headcount] is INCLUSIVE at both ends", {
  sh <- 1000
  expect_true(validate_urps_projection(base(supply_headcount = sh, supply_clinical_fte = 0)))    # lower edge
  expect_true(validate_urps_projection(base(supply_headcount = sh, supply_clinical_fte = sh)))   # upper edge
  expect_error(validate_urps_projection(base(supply_headcount = sh, supply_clinical_fte = sh + 1e-9)),
               "cannot exceed")                                                                   # just above headcount
  expect_error(validate_urps_projection(base(supply_headcount = sh, supply_clinical_fte = -1e-9)),
               "non-negative")                                                                    # just below 0
})

test_that("entrants / exits non-negativity boundary: 0 passes, just-below fails", {
  expect_true(validate_urps_projection(base(entrants = 0, exits = 0, net_change = 0)))
  expect_error(validate_urps_projection(base(entrants = -1e-9, exits = 0, net_change = -1e-9)),
               "non-negative")
})

test_that("flow-identity tolerance is INCLUSIVE at tol (diff > tol fails, diff == tol passes)", {
  # net_change = entrants - exits + delta; the check fails only when |delta| > tol
  mk <- function(delta, tol = 1e-6)
    validate_urps_projection(base(entrants = 40, exits = 55, net_change = -15 + delta), tol = tol)
  expect_true(mk(delta = 1e-6))                       # delta == tol -> not > tol -> passes
  expect_true(mk(delta = -1e-6))                      # symmetric edge
  expect_error(mk(delta = 1e-5), "flow identity")     # comfortably over tol
  # a tightened tolerance moves the edge in
  expect_error(mk(delta = 1e-6, tol = 1e-9), "flow identity")
})

test_that("row-count boundary: an empty table (0 rows) is rejected, 1 row is enough", {
  empty <- base()[0, , drop = FALSE]
  expect_equal(nrow(empty), 0L)
  expect_error(validate_urps_projection(empty), "empty")
  expect_true(validate_urps_projection(base()))       # the minimal 1-row table validates
})

# ---- the scenario-guard length boundaries -----------------------------------

test_that("scenario guards handle the empty / singleton length boundaries", {
  expect_error(validate_urps_scenarios(character(0)), "no scenario_id values")  # length 0
  expect_true(validate_urps_scenarios(urps_scenario_ids()[1]))                  # length 1, valid
  expect_identical(is_urps_scenario(character(0)), logical(0))                  # empty in, empty out
  expect_length(is_urps_scenario(urps_scenario_ids()), length(urps_scenario_ids()))
})
