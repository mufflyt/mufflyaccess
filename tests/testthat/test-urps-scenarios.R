library(testthat)
library(mufflyaccess)

test_that("the registry is a well-formed, versioned dictionary", {
  d <- urps_scenarios()
  expect_s3_class(d, "data.frame")
  req <- c("scenario_id", "family", "label", "entrant_multiplier",
           "retirement_shift_years", "late_career_fte_factor",
           "late_career_fte_onset_age", "requires_fte_model", "description")
  expect_true(all(req %in% names(d)))
  expect_false(anyDuplicated(d$scenario_id) > 0)
  expect_match(URPS_SCENARIO_REGISTRY_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  expect_setequal(urps_scenario_ids(), d$scenario_id)
})

test_that("baseline is the neutral lever origin", {
  b <- urps_scenario("baseline")
  expect_identical(b$family, "reference")
  expect_equal(b$entrant_multiplier, 1)
  expect_equal(b$retirement_shift_years, 0L)
  expect_equal(b$late_career_fte_factor, 1)
  expect_true(is.na(b$late_career_fte_onset_age))
  expect_false(b$requires_fte_model)
  expect_null(b$components)
})

test_that("lever definitions match the named scenarios", {
  expect_equal(urps_scenario("fellowship_plus_10pct")$entrant_multiplier, 1.10)
  expect_equal(urps_scenario("fellowship_constrained")$entrant_multiplier, 0.90)
  expect_equal(urps_scenario("retire_2yr_earlier")$retirement_shift_years, -2L)
  expect_equal(urps_scenario("retire_5yr_earlier")$retirement_shift_years, -5L)
  expect_equal(urps_scenario("retire_2yr_later")$retirement_shift_years, 2L)
  fte <- urps_scenario("lower_late_career_fte")
  expect_equal(fte$late_career_fte_factor, 0.75)
  expect_equal(fte$late_career_fte_onset_age, 60L)
  expect_true(fte$requires_fte_model)
})

test_that("composites reconstruct from their components (un-driftable)", {
  d <- urps_scenarios()
  compose <- function(cid, components) {
    cr <- d[match(components, d$scenario_id), , drop = FALSE]
    onset <- cr$late_career_fte_onset_age[!is.na(cr$late_career_fte_onset_age)]
    got <- d[d$scenario_id == cid, ]
    expect_equal(got$entrant_multiplier, prod(cr$entrant_multiplier))
    expect_equal(got$retirement_shift_years, as.integer(sum(cr$retirement_shift_years)))
    expect_equal(got$late_career_fte_factor, prod(cr$late_career_fte_factor))
    expect_equal(got$late_career_fte_onset_age,
                 if (length(onset)) as.integer(min(onset)) else NA_integer_)
    expect_equal(got$requires_fte_model, any(cr$requires_fte_model))
  }
  compose("combined_pessimistic",
          c("retire_2yr_earlier", "fellowship_constrained", "lower_late_career_fte"))
  compose("combined_investment", c("retire_2yr_later", "fellowship_plus_10pct"))
  expect_identical(urps_scenario("combined_pessimistic")$components,
                   c("retire_2yr_earlier", "fellowship_constrained", "lower_late_career_fte"))
})

test_that("requires_fte_model iff an FTE adjustment is present", {
  d <- urps_scenarios()
  expect_equal(d$requires_fte_model, d$late_career_fte_factor != 1)
  # an FTE adjustment must carry an onset age, and none otherwise
  expect_equal(!is.na(d$late_career_fte_onset_age), d$late_career_fte_factor != 1)
})

test_that("urps_scenario() is a fail-loud single lookup", {
  expect_type(urps_scenario("baseline"), "list")
  expect_error(urps_scenario("nope"), "unknown scenario_id")
  expect_error(urps_scenario(c("baseline", "baseline")), "single string")
  expect_error(urps_scenario(NA_character_), "single string")
  expect_identical(urps_scenario("baseline")$registry_version, URPS_SCENARIO_REGISTRY_VERSION)
})

test_that("is_urps_scenario() is a vectorised, non-erroring predicate", {
  expect_equal(is_urps_scenario(c("baseline", "typo", NA)), c(TRUE, FALSE, FALSE))
  expect_equal(is_urps_scenario(character(0)), logical(0))
})

test_that("validate_urps_scenarios() guards vectors and data.frames", {
  expect_true(validate_urps_scenarios(urps_scenario_ids()))
  expect_true(validate_urps_scenarios(
    data.frame(scenario_id = c("baseline", "retire_2yr_later"), v = 1:2)))
  expect_error(validate_urps_scenarios("earlier_retirement"), "unregistered scenario_id")
  expect_error(validate_urps_scenarios(data.frame(x = 1)), "no `scenario_id` column")
  expect_error(validate_urps_scenarios(character(0)), "no scenario_id values")
  expect_error(validate_urps_scenarios(42), "character vector or a data.frame")
})
