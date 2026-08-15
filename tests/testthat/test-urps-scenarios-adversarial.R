library(testthat)
library(mufflyaccess)

# ==============================================================================
# Semantic + adversarial coverage for the scenario dictionary. "Semantic" =
# the lever values must *mean* the right thing (direction, ordering, family
# coherence); "adversarial" = near-miss / hostile ids must never slip past the
# registered-scenario guard.
# ==============================================================================

sc <- function(id) urps_scenario(id)

# ---- SEMANTIC: directions and orderings -------------------------------------

test_that("retirement scenarios are ordered earlier < baseline < later", {
  expect_lt(
    sc("retire_5yr_earlier")$retirement_shift_years,
    sc("retire_2yr_earlier")$retirement_shift_years
  )
  expect_lt(sc("retire_2yr_earlier")$retirement_shift_years, 0L) # earlier = negative
  expect_gt(sc("retire_2yr_later")$retirement_shift_years, 0L) # later   = positive
  # the named magnitudes are exactly what the labels claim
  expect_equal(sc("retire_5yr_earlier")$retirement_shift_years, -5L)
  expect_equal(sc("retire_2yr_later")$retirement_shift_years, 2L)
})

test_that("entry scenarios bracket the baseline entrant rate", {
  expect_gt(sc("fellowship_plus_10pct")$entrant_multiplier, 1)
  expect_lt(sc("fellowship_constrained")$entrant_multiplier, 1)
  # expansion and constraint are symmetric 10% moves
  expect_equal(sc("fellowship_plus_10pct")$entrant_multiplier +
    sc("fellowship_constrained")$entrant_multiplier, 2.0)
})

test_that("composites point the right way on every axis they touch", {
  inv <- sc("combined_investment") # favourable: more entrants AND later exit
  expect_gte(inv$entrant_multiplier, 1)
  expect_gte(inv$retirement_shift_years, 0L)
  pes <- sc("combined_pessimistic") # adverse: fewer entrants, earlier exit, lower FTE
  expect_lte(pes$entrant_multiplier, 1)
  expect_lte(pes$retirement_shift_years, 0L)
  expect_lte(pes$late_career_fte_factor, 1)
  # the pessimistic composite is adverse on strictly more axes than any single lever
  expect_true(pes$entrant_multiplier < 1 && pes$retirement_shift_years < 0L &&
    pes$late_career_fte_factor < 1)
})

# ---- SEMANTIC: family coherence + no accidental baseline clones -------------

test_that("a single-lever family perturbs only its own lever", {
  d <- urps_scenarios()
  ret <- d[d$family == "retirement", ]
  expect_true(all(ret$entrant_multiplier == 1 & ret$late_career_fte_factor == 1))
  ent <- d[d$family == "entry", ]
  expect_true(all(ent$retirement_shift_years == 0L & ent$late_career_fte_factor == 1))
  fte <- d[d$family == "fte", ]
  expect_true(all(fte$entrant_multiplier == 1 & fte$retirement_shift_years == 0L))
})

test_that("baseline is the unique neutral origin; every other scenario moves a lever", {
  d <- urps_scenarios()
  # neutral across BOTH the supply levers and the demand levers -- baseline alone
  neutral <- d$entrant_multiplier == 1 & d$retirement_shift_years == 0L &
    d$late_career_fte_factor == 1 &
    d$demand_obesity_prev_shift == 0 & d$demand_insurance_expansion_factor == 1 &
    d$demand_managed_care_factor == 1 & d$demand_retail_clinic_share == 0
  expect_identical(d$scenario_id[neutral], "baseline") # exactly one fully-neutral row
  expect_true(all(d$family[!neutral] != "reference")) # non-neutral => not reference
})

test_that("requires_fte_model marks exactly the FTE-touching scenarios", {
  d <- urps_scenarios()
  expect_identical(
    sort(d$scenario_id[d$requires_fte_model]),
    sort(d$scenario_id[d$late_career_fte_factor != 1])
  )
  # and those are the only rows carrying an onset age
  expect_identical(
    sort(d$scenario_id[!is.na(d$late_career_fte_onset_age)]),
    sort(d$scenario_id[d$requires_fte_model])
  )
})

# ---- ADVERSARIAL: near-miss and hostile ids must be rejected ----------------

test_that("membership is exact: case, whitespace, and partials do not match", {
  # every valid id is accepted...
  expect_true(all(is_urps_scenario(urps_scenario_ids())))
  # ...but nothing near it is
  hostile <- c(
    "Baseline", "BASELINE", " baseline", "baseline ", "baseline\t",
    "base", "baselin", "baseline_x", "fellowship_plus_10",
    "fellowship+10pct", "retire_2yr_early", "earlier_retirement",
    "combined-investment", "", "  "
  )
  expect_false(any(is_urps_scenario(hostile)))
  for (h in hostile) expect_error(urps_scenario(h), "unknown scenario_id")
})

test_that("a single bad id among many good ones is still caught", {
  ids <- c(urps_scenario_ids(), "sneaky_extra")
  expect_error(validate_urps_scenarios(ids), "sneaky_extra")
  expect_error(validate_urps_scenarios(sample(ids)), "unregistered scenario_id")
})

test_that("guard survives factor / NA / non-character columns without false negatives", {
  # a factor scenario_id column with only valid levels validates
  ok <- data.frame(scenario_id = factor(c("baseline", "retire_2yr_later")), v = 1:2)
  expect_true(validate_urps_scenarios(ok))
  # a factor hiding an invalid level is caught
  bad <- data.frame(scenario_id = factor(c("baseline", "totally_made_up")))
  expect_error(validate_urps_scenarios(bad), "totally_made_up")
  # all-NA scenario_id is rejected, not silently passed
  expect_error(validate_urps_scenarios(data.frame(scenario_id = NA)), "unregistered|NA")
})

test_that("predicate coerces non-character input to FALSE, never errors", {
  expect_equal(is_urps_scenario(c(1, 2, 3)), c(FALSE, FALSE, FALSE))
  expect_equal(is_urps_scenario(NA), FALSE)
  expect_false(any(is_urps_scenario(factor("nope"))))
})

test_that("urps_scenario() rejects non-scalar and malformed keys", {
  expect_error(urps_scenario(c("baseline", "baseline")), "single string")
  expect_error(urps_scenario(character(0)), "single string")
  expect_error(urps_scenario(NA_character_), "single string")
  expect_error(urps_scenario(1L), "single string")
})
