# URPS clinical-FTE model (Phase 3): the canonical headcount -> clinical-FTE
# weighting that fills the projection contract's supply_clinical_fte column.
library(testthat)

test_that("pathway clinical time is the canonical ABOG 1.0 / ABU 0.70", {
  expect_equal(unname(URPS_FTE_PATHWAY_CLINICAL_TIME[["ABOG"]]), 1.00)
  expect_equal(unname(URPS_FTE_PATHWAY_CLINICAL_TIME[["ABU"]]), 0.70)
})

test_that("the age curve is served with the expected columns", {
  d <- urps_fte_age_curve()
  expect_true(all(c("age", "rel_to_peak") %in% names(d)))
  expect_type(d$age, "integer")
  expect_true(all(d$rel_to_peak >= 0))
})

test_that("the weight is age productivity x pathway clinical time x late factor", {
  curve <- urps_fte_age_curve()
  a <- 50L
  rel <- curve$rel_to_peak[match(a, curve$age)]
  expect_equal(urps_fte_weight(a, "ABOG"), rel) # full clinical time
  expect_equal(urps_fte_weight(a, "ABU"), rel * 0.70) # ABU 0.70
  # late-career factor applies only at/after the onset age
  expect_equal(
    urps_fte_weight(65L, "ABOG", late_from_age = 60L, late_factor = 0.75),
    curve$rel_to_peak[match(65L, curve$age)] * 0.75
  )
  expect_equal(
    urps_fte_weight(55L, "ABOG", late_from_age = 60L, late_factor = 0.75),
    curve$rel_to_peak[match(55L, curve$age)]
  ) # below onset: unaffected
  # vectorised over mixed pathways
  w <- urps_fte_weight(c(50L, 50L), c("ABOG", "ABU"))
  expect_equal(w[2] / w[1], 0.70, tolerance = 1e-9)
  # ages are clamped to the curve support
  expect_equal(
    urps_fte_weight(200L, "ABOG"),
    curve$rel_to_peak[match(max(curve$age), curve$age)]
  )
})

test_that("effective FTE is additive and the scale anchors a reference cohort to headcount", {
  cs <- data.frame(
    age = c(45L, 62L, 45L, 62L),
    pathway = c("ABOG", "ABOG", "ABU", "ABU"), n = c(10, 5, 4, 2)
  )
  scale <- urps_fte_scale(cs) # target = headcount (21)
  expect_equal(urps_effective_fte(cs, scale), sum(cs$n), tolerance = 1e-9)
  abog <- cs[cs$pathway == "ABOG", ]
  abu <- cs[cs$pathway == "ABU", ]
  expect_equal(urps_effective_fte(abog, scale) + urps_effective_fte(abu, scale),
    urps_effective_fte(cs, scale),
    tolerance = 1e-9
  ) # additive across pathways
  expect_error(
    urps_fte_scale(data.frame(age = 45L, pathway = "ABOG", n = 0)),
    "non-positive"
  )
})

test_that("the FTE model composes with the scenario registry's late-career lever", {
  skip_if_not("urps_scenario" %in% getNamespaceExports("mufflyaccess"))
  # the late lever is defined ONCE in the registry; the FTE model just applies it
  lever <- urps_scenario("lower_late_career_fte")
  expect_equal(lever$late_career_fte_factor, 0.75)
  expect_equal(lever$late_career_fte_onset_age, 60L)
  curve <- urps_fte_age_curve()
  w <- urps_fte_weight(65L, "ABOG",
    late_from_age = lever$late_career_fte_onset_age,
    late_factor   = lever$late_career_fte_factor
  )
  expect_equal(w, curve$rel_to_peak[match(65L, curve$age)] * 0.75)
  # baseline lever is neutral -> no FTE reduction
  base <- urps_scenario("baseline")
  expect_equal(base$late_career_fte_factor, 1)
  expect_true(is.na(base$late_career_fte_onset_age))
})

test_that("an FTE-populated projection satisfies the projection contract", {
  skip_if_not("validate_urps_projection" %in% getNamespaceExports("mufflyaccess"))
  # build a tiny 2-year projection with FTE filled by the model and check it passes
  cs <- data.frame(
    age = c(45L, 62L, 45L, 62L),
    pathway = c("ABOG", "ABOG", "ABU", "ABU"), n = c(700, 300, 200, 79)
  )
  scale <- urps_fte_scale(cs)
  fte0 <- urps_effective_fte(cs, scale)
  proj <- data.frame(
    year = c(2023L, 2024L), scenario_id = "baseline", specialty = "URPS",
    certification_pathway = "ABOG_PLUS_ABU", geography_type = "national", geography_id = "US",
    supply_headcount = c(sum(cs$n), sum(cs$n) + 50L - 12L),
    supply_clinical_fte = c(round(fte0, 1), NA),
    lower_95 = c(NA, NA), upper_95 = c(NA, NA),
    entrants = c(NA, 50L), exits = c(NA, 12L), net_change = c(NA, 38L),
    stringsAsFactors = FALSE
  )
  expect_true(validate_urps_projection(proj))
})
