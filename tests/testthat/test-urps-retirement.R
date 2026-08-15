library(testthat)

# urps_retirement.R: logistic survival curve model for URPS retirement.

# ---- parameter table ---------------------------------------------------------

test_that("params table has required columns, 4 rows, and valid calibrated values", {
  d <- urps_retirement_params()
  expect_s3_class(d, "data.frame")
  expect_setequal(
    names(d),
    c("sex", "certification_pathway", "mu_years", "sigma_years", "calibration_status")
  )
  expect_equal(nrow(d), 4L)
  expect_setequal(d$sex, c("female", "male"))
  expect_setequal(d$certification_pathway, c("ABOG", "ABU"))
  expect_true(all(d$mu_years >= 50 & d$mu_years <= 80))
  expect_true(all(d$sigma_years >= 1 & d$sigma_years <= 15))
  expect_true(all(d$calibration_status == "calibrated_from_literature"))
  expect_equal(anyDuplicated(paste(d$sex, d$certification_pathway)), 0L)
})

test_that("params table carries source, formula, and curve_type attributes", {
  d <- urps_retirement_params()
  expect_false(is.null(attr(d, "source")))
  expect_false(is.null(attr(d, "formula")))
  expect_equal(attr(d, "curve_type"), "logistic_survival")
  expect_match(attr(d, "formula"), "S\\(age")
})

test_that("female mu is less than male mu for each pathway (female physicians retire earlier)", {
  d <- urps_retirement_params()
  for (pw in c("ABOG", "ABU")) {
    mu_f <- d$mu_years[d$sex == "female" & d$certification_pathway == pw]
    mu_m <- d$mu_years[d$sex == "male" & d$certification_pathway == pw]
    expect_lt(mu_f, mu_m,
      label = sprintf("female mu < male mu for %s", pw)
    )
  }
})

# ---- urps_p_still_active: definitional and boundary --------------------------

test_that("at age == mu, p_still_active equals exactly 0.5 (logistic definition)", {
  d <- urps_retirement_params()
  for (i in seq_len(nrow(d))) {
    p <- urps_p_still_active(d$mu_years[i], d$sex[i], d$certification_pathway[i])
    expect_equal(p, 0.5,
      tolerance = 1e-9,
      label = sprintf("p_still_active at mu for %s/%s", d$sex[i], d$certification_pathway[i])
    )
  }
})

test_that("survival is near 1 at age 35 and near 0 at age 90 for all groups", {
  d <- urps_retirement_params()
  for (i in seq_len(nrow(d))) {
    s_low <- urps_p_still_active(35, d$sex[i], d$certification_pathway[i])
    s_high <- urps_p_still_active(90, d$sex[i], d$certification_pathway[i])
    expect_gt(s_low, 0.99,
      label = sprintf("S(35) > 0.99 for %s/%s", d$sex[i], d$certification_pathway[i])
    )
    expect_lt(s_high, 0.01,
      label = sprintf("S(90) < 0.01 for %s/%s", d$sex[i], d$certification_pathway[i])
    )
  }
})

test_that("survival is strictly decreasing with age (monotone)", {
  s <- urps_p_still_active(35:80, "female", "ABOG")
  expect_true(all(diff(s) < 0))
})

test_that("female p_still_active is lower than male at the same mid-retirement age", {
  for (pw in c("ABOG", "ABU")) {
    s_f <- urps_p_still_active(65, "female", pw)
    s_m <- urps_p_still_active(65, "male", pw)
    expect_lt(s_f, s_m,
      label = sprintf("female < male survival at 65 for %s", pw)
    )
  }
})

test_that("urps_p_still_active is correctly vectorized over age", {
  out <- urps_p_still_active(35:80, "male", "ABOG")
  expect_length(out, 46L)
  expect_equal(
    urps_p_still_active(c(60, 65, 70), "female", "ABU"),
    c(
      urps_p_still_active(60, "female", "ABU"),
      urps_p_still_active(65, "female", "ABU"),
      urps_p_still_active(70, "female", "ABU")
    )
  )
})

# ---- scenario shift ----------------------------------------------------------

test_that("retirement_shift_years = 2 at age 68 matches shift = 0 at age 66", {
  # effective_age = age - shift_years = 68 - 2 = 66 — same computation
  p_shifted <- urps_p_still_active(68, "female", "ABOG", retirement_shift_years = 2L)
  p_baseline <- urps_p_still_active(66, "female", "ABOG", retirement_shift_years = 0L)
  expect_equal(p_shifted, p_baseline, tolerance = 1e-12)
})

test_that("retirement_shift_years = -2 at age 64 matches shift = 0 at age 66", {
  p_shifted <- urps_p_still_active(64, "male", "ABOG", retirement_shift_years = -2L)
  p_baseline <- urps_p_still_active(66, "male", "ABOG", retirement_shift_years = 0L)
  expect_equal(p_shifted, p_baseline, tolerance = 1e-12)
})

test_that("shift = -2 (retire earlier) produces lower survival than baseline at mid ages", {
  ages <- 60:72
  s_early <- urps_p_still_active(ages, "female", "ABOG", retirement_shift_years = -2L)
  s_base <- urps_p_still_active(ages, "female", "ABOG", retirement_shift_years = 0L)
  expect_true(all(s_early < s_base))
})

test_that("shift = +2 (retire later) produces higher survival than baseline at mid ages", {
  ages <- 60:72
  s_late <- urps_p_still_active(ages, "male", "ABOG", retirement_shift_years = 2L)
  s_base <- urps_p_still_active(ages, "male", "ABOG", retirement_shift_years = 0L)
  expect_true(all(s_late > s_base))
})

test_that("scenario lever values from urps_scenario() integrate correctly", {
  shift_e <- urps_scenario("retire_2yr_earlier")$retirement_shift_years
  shift_l <- urps_scenario("retire_2yr_later")$retirement_shift_years
  expect_equal(shift_e, -2L)
  expect_equal(shift_l, 2L)
  # at mu=65: earlier -> lower, later -> higher
  s_earlier <- urps_p_still_active(65, "female", "ABOG", retirement_shift_years = shift_e)
  s_baseline <- urps_p_still_active(65, "female", "ABOG")
  s_later <- urps_p_still_active(65, "female", "ABOG", retirement_shift_years = shift_l)
  expect_lt(s_earlier, s_baseline)
  expect_gt(s_later, s_baseline)
})

# ---- urps_retirement_hazard --------------------------------------------------

test_that("annual_hazard is non-negative and at most 1 everywhere", {
  for (pw in c("ABOG", "ABU")) {
    for (sx in c("female", "male")) {
      h <- urps_retirement_hazard(35:85, sx, pw)
      expect_true(all(h >= 0),
        label = sprintf("h >= 0 for %s/%s", sx, pw)
      )
      expect_true(all(h <= 1),
        label = sprintf("h <= 1 for %s/%s", sx, pw)
      )
    }
  }
})

test_that("hazard is monotonically increasing with age (logistic IFR property)", {
  # The logistic survival function is IFR (increasing failure rate): h(age) = (1 - S(age)) / sigma,
  # which increases as S decreases. This is the correct behavior for late-career retirement.
  d <- urps_retirement_params()
  for (i in seq_len(nrow(d))) {
    h <- urps_retirement_hazard(35:85, d$sex[i], d$certification_pathway[i])
    expect_true(all(diff(h) > 0),
      label = sprintf("hazard monotone increasing for %s/%s", d$sex[i], d$certification_pathway[i])
    )
  }
})

test_that("hazard is consistent with the survival function: h = (S(age-1) - S(age)) / S(age-1)", {
  ages <- 55:75
  s_prev <- urps_p_still_active(ages - 1, "female", "ABOG")
  s_curr <- urps_p_still_active(ages, "female", "ABOG")
  expected_h <- (s_prev - s_curr) / s_prev
  actual_h <- urps_retirement_hazard(ages, "female", "ABOG")
  expect_equal(actual_h, pmin(pmax(expected_h, 0), 1), tolerance = 1e-12)
})

test_that("shift = -2 produces higher hazard than baseline at mid-retirement ages", {
  ages <- 60:70
  h_early <- urps_retirement_hazard(ages, "female", "ABOG", retirement_shift_years = -2L)
  h_base <- urps_retirement_hazard(ages, "female", "ABOG", retirement_shift_years = 0L)
  expect_true(all(h_early > h_base))
})

# ---- urps_survival_curve -----------------------------------------------------

test_that("urps_survival_curve returns data.frame with correct columns and dimensions", {
  curve <- urps_survival_curve("female", "ABOG")
  expect_s3_class(curve, "data.frame")
  expect_setequal(names(curve), c("age", "p_still_active", "annual_hazard"))
  expect_equal(nrow(curve), length(35:80))
  expect_equal(curve$age, as.integer(35:80))
})

test_that("urps_survival_curve respects a custom age_range", {
  curve <- urps_survival_curve("male", "ABU", age_range = 50:70)
  expect_equal(nrow(curve), 21L)
  expect_equal(curve$age, as.integer(50:70))
})

test_that("urps_survival_curve values match the component functions", {
  curve <- urps_survival_curve("female", "ABU",
    retirement_shift_years = -2L, age_range = 55:75
  )
  expect_equal(
    curve$p_still_active,
    urps_p_still_active(55:75, "female", "ABU", retirement_shift_years = -2L)
  )
  expect_equal(
    curve$annual_hazard,
    urps_retirement_hazard(55:75, "female", "ABU", retirement_shift_years = -2L)
  )
})

test_that("p_still_active in survival_curve is strictly decreasing with age", {
  curve <- urps_survival_curve("male", "ABOG")
  expect_true(all(diff(curve$p_still_active) < 0))
})

# ---- version -----------------------------------------------------------------

test_that("URPS_RETIREMENT_CURVE_VERSION is a semver string", {
  expect_match(URPS_RETIREMENT_CURVE_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

# ---- fail-loud on bad inputs -------------------------------------------------

test_that("unknown sex produces a hard error mentioning 'female' and 'male'", {
  expect_error(urps_p_still_active(65, "nonbinary", "ABOG"), "female.*male|male.*female")
  expect_error(urps_retirement_hazard(65, "F", "ABOG"), "female.*male|male.*female")
  expect_error(urps_survival_curve("Male", "ABOG"), "female.*male|male.*female")
})

test_that("unknown pathway produces a hard error mentioning 'ABOG' and 'ABU'", {
  expect_error(urps_p_still_active(65, "female", "ABMS"), "ABOG.*ABU|ABU.*ABOG")
  expect_error(urps_retirement_hazard(65, "male", "ABOG_PLUS_ABU"), "ABOG.*ABU|ABU.*ABOG")
  expect_error(urps_survival_curve("female", "ABU_NET_NEW"), "ABOG.*ABU|ABU.*ABOG")
})

test_that("non-finite retirement_shift_years produces a hard error", {
  expect_error(urps_p_still_active(65, "female", "ABOG", Inf), "finite")
  expect_error(urps_p_still_active(65, "female", "ABOG", NA), "finite")
  expect_error(urps_retirement_hazard(65, "male", "ABU", NaN), "finite")
})
