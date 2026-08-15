library(testthat)

# urps_projection_ci.R: parametric bootstrap confidence interval module tests.

# ---- version -----------------------------------------------------------------

test_that("URPS_PROJECTION_CI_VERSION is semver", {
  expect_match(mufflyaccess:::URPS_PROJECTION_CI_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

# ---- urps_ci_param_draw ------------------------------------------------------

test_that("urps_ci_param_draw returns a list with the required elements", {
  d <- urps_ci_param_draw(seed = 1L)
  expect_true(is.list(d))
  expect_true(all(c(
    "retirement_sigma_sd", "retirement_shift",
    "entrant_scale", "lfp_intercept_shift"
  ) %in% names(d)))
})

test_that("urps_ci_param_draw is reproducible with same seed", {
  a <- urps_ci_param_draw(seed = 42L)
  b <- urps_ci_param_draw(seed = 42L)
  expect_identical(a, b)
})

test_that("urps_ci_param_draw differs with different seeds", {
  a <- urps_ci_param_draw(seed = 1L)
  b <- urps_ci_param_draw(seed = 2L)
  expect_false(identical(a$retirement_shift, b$retirement_shift))
})

test_that("urps_ci_param_draw passes retirement_sigma_sd through", {
  d <- urps_ci_param_draw(retirement_sigma_sd = 1.0, seed = 7L)
  expect_equal(d$retirement_sigma_sd, 1.0)
})

test_that("urps_ci_param_draw entrant_scale is positive (mean 1, cv=0.077)", {
  # Draw many; expect mean ≈ 1 and all positive with overwhelming probability
  set.seed(99)
  scales <- replicate(500, urps_ci_param_draw()$entrant_scale)
  expect_true(all(scales > 0))
  expect_equal(mean(scales), 1.0, tolerance = 0.05)
})

test_that("urps_ci_param_draw rejects invalid retirement_sigma_sd", {
  expect_error(urps_ci_param_draw(retirement_sigma_sd = 0), "retirement_sigma_sd")
  expect_error(urps_ci_param_draw(retirement_sigma_sd = -1), "retirement_sigma_sd")
  expect_error(urps_ci_param_draw(retirement_sigma_sd = Inf), "retirement_sigma_sd")
})

test_that("urps_ci_param_draw rejects entrant_cv >= 1 or <= 0", {
  expect_error(urps_ci_param_draw(entrant_cv = 0), "entrant_cv")
  expect_error(urps_ci_param_draw(entrant_cv = 1.0), "entrant_cv")
  expect_error(urps_ci_param_draw(entrant_cv = 2.0), "entrant_cv")
})

test_that("urps_ci_param_draw rejects non-integer seed", {
  expect_error(urps_ci_param_draw(seed = 1.5), "seed")
})

test_that("urps_ci_param_draw accepts NULL seed without error", {
  expect_no_error(urps_ci_param_draw(seed = NULL))
})

# ---- urps_projection_ci ------------------------------------------------------

# Minimal project_fn for testing: flat headcount with entrant_scale applied.
.make_project_fn <- function(headcount = 1300, fte = 900) {
  function(scenario_id, years, param_draw) {
    data.frame(
      year                = years,
      scenario_id         = scenario_id,
      supply_headcount    = headcount * param_draw$entrant_scale,
      supply_clinical_fte = fte * param_draw$entrant_scale,
      stringsAsFactors    = FALSE
    )
  }
}

test_that("urps_projection_ci returns a data.frame with correct columns", {
  ci <- urps_projection_ci(.make_project_fn(),
    B = 10L, seed = 1L,
    years = 2025:2027
  )
  expect_s3_class(ci, "data.frame")
  expect_true(all(c(
    "year", "scenario_id",
    "lower_headcount_95", "upper_headcount_95",
    "lower_fte_95", "upper_fte_95"
  ) %in% names(ci)))
})

test_that("urps_projection_ci returns one row per (year, scenario_id)", {
  ci <- urps_projection_ci(.make_project_fn(),
    scenarios = "baseline",
    years = 2025:2030, B = 10L, seed = 1L
  )
  expect_equal(nrow(ci), 6L) # 6 years × 1 scenario
})

test_that("urps_projection_ci lower <= upper for headcount", {
  ci <- urps_projection_ci(.make_project_fn(),
    B = 20L, seed = 5L,
    years = 2025:2030
  )
  expect_true(all(ci$lower_headcount_95 <= ci$upper_headcount_95))
})

test_that("urps_projection_ci lower <= upper for fte", {
  ci <- urps_projection_ci(.make_project_fn(),
    B = 20L, seed = 5L,
    years = 2025:2030
  )
  expect_true(all(ci$lower_fte_95 <= ci$upper_fte_95))
})

test_that("urps_projection_ci fte is NA when project_fn returns NA fte", {
  fn <- function(scenario_id, years, param_draw) {
    data.frame(
      year = years, scenario_id = scenario_id,
      supply_headcount = 1300,
      supply_clinical_fte = NA_real_,
      stringsAsFactors = FALSE
    )
  }
  ci <- urps_projection_ci(fn, B = 10L, seed = 1L, years = 2025:2026)
  expect_true(all(is.na(ci$lower_fte_95)))
  expect_true(all(is.na(ci$upper_fte_95)))
})

test_that("urps_projection_ci is reproducible with same seed", {
  fn <- .make_project_fn()
  a <- urps_projection_ci(fn, B = 20L, seed = 77L, years = 2025:2027)
  b <- urps_projection_ci(fn, B = 20L, seed = 77L, years = 2025:2027)
  expect_identical(a, b)
})

test_that("urps_projection_ci wider interval with larger entrant_cv", {
  fn <- .make_project_fn()
  ci_narrow <- urps_projection_ci(fn,
    B = 200L, seed = 1L, years = 2030:2030,
    entrant_cv = 0.01
  )
  ci_wide <- urps_projection_ci(fn,
    B = 200L, seed = 1L, years = 2030:2030,
    entrant_cv = 0.30
  )
  narrow_w <- ci_narrow$upper_headcount_95 - ci_narrow$lower_headcount_95
  wide_w <- ci_wide$upper_headcount_95 - ci_wide$lower_headcount_95
  expect_true(wide_w > narrow_w)
})

test_that("urps_projection_ci rejects B < 10", {
  expect_error(
    urps_projection_ci(.make_project_fn(), B = 5L),
    "B must be a single integer >= 10"
  )
})

test_that("urps_projection_ci rejects non-function project_fn", {
  expect_error(
    urps_projection_ci("not_a_function", B = 10L),
    "project_fn must be a function"
  )
})

test_that("urps_projection_ci rejects unregistered scenario", {
  expect_error(
    urps_projection_ci(.make_project_fn(), scenarios = "fantasy_scenario", B = 10L),
    "registered"
  )
})

test_that("urps_projection_ci rejects bad probs", {
  fn <- .make_project_fn()
  expect_error(urps_projection_ci(fn, probs = c(0.5, 0.3), B = 10L), "probs")
  expect_error(urps_projection_ci(fn, probs = c(0, 0.975), B = 10L), "probs")
  expect_error(urps_projection_ci(fn, probs = c(0.025, 1), B = 10L), "probs")
})

test_that("urps_projection_ci errors if project_fn returns non-data.frame", {
  bad_fn <- function(scenario_id, years, param_draw) list(a = 1)
  expect_error(
    urps_projection_ci(bad_fn, B = 10L, years = 2025:2026),
    "data.frame"
  )
})

test_that("urps_projection_ci errors if project_fn result is missing required columns", {
  bad_fn <- function(scenario_id, years, param_draw) {
    data.frame(year = years, stringsAsFactors = FALSE)
  }
  expect_error(
    urps_projection_ci(bad_fn, B = 10L, years = 2025:2026),
    "missing column"
  )
})
