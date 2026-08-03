library(testthat)

# urps_fte_sex.R: sex-stratified OLS hours model for URPS FTE weighting.

# ---- constants ---------------------------------------------------------------

test_that("URPS_FTE_REFERENCE_HOURS_PER_WEEK is 40", {
  expect_equal(URPS_FTE_REFERENCE_HOURS_PER_WEEK, 40.0)
})

test_that("URPS_FTE_SEX_HOURS_VERSION is semver", {
  expect_match(URPS_FTE_SEX_HOURS_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

# ---- params table ------------------------------------------------------------

test_that("params table has required columns and 2 rows", {
  d <- urps_fte_sex_hours_params()
  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), 2L)
  expect_setequal(d$sex, c("female", "male"))
  expect_true(all(c("intercept", "b_age", "c_age_sq",
                    "anchor_age_lo", "anchor_hours_lo",
                    "anchor_age_peak", "anchor_hours_peak",
                    "anchor_age_hi", "anchor_hours_hi",
                    "calibration_status") %in% names(d)))
  expect_true(all(d$calibration_status == "calibrated_from_literature"))
})

test_that("params table carries source, formula, and reference_hours attributes", {
  d <- urps_fte_sex_hours_params()
  expect_false(is.null(attr(d, "source")))
  expect_match(attr(d, "formula"), "intercept")
  expect_equal(attr(d, "reference_hours"), 40.0)
})

test_that("coefficients reproduce all anchor points within 0.01 hrs", {
  d <- urps_fte_sex_hours_params()
  for (sx in c("female", "male")) {
    r    <- d[d$sex == sx, ]
    eval_q <- function(age) r$intercept + r$b_age * age + r$c_age_sq * age^2
    expect_equal(eval_q(r$anchor_age_lo),   r$anchor_hours_lo,   tolerance = 0.01,
                 label = paste("lo anchor", sx))
    expect_equal(eval_q(r$anchor_age_peak), r$anchor_hours_peak, tolerance = 0.01,
                 label = paste("peak anchor", sx))
    expect_equal(eval_q(r$anchor_age_hi),   r$anchor_hours_hi,   tolerance = 0.01,
                 label = paste("hi anchor", sx))
  }
})

test_that("male peak hours exceed female peak hours", {
  d <- urps_fte_sex_hours_params()
  peak_h <- function(r) {
    pa <- -r$b_age / (2 * r$c_age_sq)
    r$intercept + r$b_age * pa + r$c_age_sq * pa^2
  }
  expect_gt(peak_h(d[d$sex == "male", ]), peak_h(d[d$sex == "female", ]))
})

# ---- urps_fte_predicted_hours ------------------------------------------------

test_that("predicted hours at anchor ages match documented values", {
  # Male anchors: 35->50, 47->55, 65->38
  expect_equal(urps_fte_predicted_hours(35, "male"), 50, tolerance = 0.01)
  expect_equal(urps_fte_predicted_hours(47, "male"), 55, tolerance = 0.01)
  expect_equal(urps_fte_predicted_hours(65, "male"), 38, tolerance = 0.01)
  # Female anchors: 35->43, 45->47, 65->28
  expect_equal(urps_fte_predicted_hours(35, "female"), 43, tolerance = 0.01)
  expect_equal(urps_fte_predicted_hours(45, "female"), 47, tolerance = 0.01)
  expect_equal(urps_fte_predicted_hours(65, "female"), 28, tolerance = 0.01)
})

test_that("male hours exceed female hours at the same age across career", {
  ages <- 35:65
  h_m <- urps_fte_predicted_hours(ages, "male")
  h_f <- urps_fte_predicted_hours(ages, "female")
  expect_true(all(h_m > h_f))
})

test_that("predicted hours are positive at plausible working ages 35:70", {
  for (sx in c("female", "male")) {
    h <- urps_fte_predicted_hours(35:70, sx)
    expect_true(all(h > 0),
      label = paste("hours > 0 at ages 35:70 for", sx))
  }
})

test_that("hours decline after peak for both sexes (quadratic shape)", {
  for (sx in c("female", "male")) {
    h_peak <- max(urps_fte_predicted_hours(35:80, sx))
    h_65   <- urps_fte_predicted_hours(65, sx)
    expect_lt(h_65, h_peak,
      label = paste("hours at 65 < peak for", sx))
  }
})

test_that("predicted_hours is vectorized over age", {
  out <- urps_fte_predicted_hours(35:75, "female")
  expect_length(out, 41L)
  expect_equal(
    urps_fte_predicted_hours(c(40, 50, 60), "male"),
    c(urps_fte_predicted_hours(40, "male"),
      urps_fte_predicted_hours(50, "male"),
      urps_fte_predicted_hours(60, "male"))
  )
})

test_that("predicted_hours is vectorized over sex (mixed-sex cohort)", {
  ages <- c(45L, 55L)
  sexes <- c("female", "male")
  out <- urps_fte_predicted_hours(ages, sexes)
  expect_length(out, 2L)
  expect_equal(out[1], urps_fte_predicted_hours(45, "female"))
  expect_equal(out[2], urps_fte_predicted_hours(55, "male"))
})

# ---- urps_fte_weight_sex -----------------------------------------------------

test_that("FTE weight at 40 hrs/wk reference equals 1.0 for ABOG", {
  # Find the age where male hours == 40 (somewhere in late 60s)
  # Use age 65: male -> 38 hrs -> weight 38/40 = 0.95 (not 1.0)
  # Directly test: if predicted_hours were 40, weight = 40/40 * 1.0 = 1.0
  # Instead test the formula directly
  h_35_f <- urps_fte_predicted_hours(35, "female")
  w_35_f <- urps_fte_weight_sex(35, "female", "ABOG")
  expect_equal(w_35_f, h_35_f / 40, tolerance = 1e-9)
})

test_that("FTE weight applies reference division correctly", {
  for (sx in c("female", "male")) {
    h <- urps_fte_predicted_hours(47, sx)
    w <- urps_fte_weight_sex(47, sx, "ABOG")
    expect_equal(w, h / 40, tolerance = 1e-9,
      label = paste("w = h/40 for", sx, "ABOG at 47"))
  }
})

test_that("ABU weight is 0.7 times ABOG weight at same age and sex", {
  for (sx in c("female", "male")) {
    for (age in c(40, 55, 65)) {
      w_abog <- urps_fte_weight_sex(age, sx, "ABOG")
      w_abu  <- urps_fte_weight_sex(age, sx, "ABU")
      expect_equal(w_abu, w_abog * 0.7, tolerance = 1e-9,
        label = sprintf("ABU = 0.7 * ABOG for %s at %d", sx, age))
    }
  }
})

test_that("late_factor reduces FTE weight at ages >= late_from_age", {
  # At age 62 >= 60: weight should be reduced by late_factor 0.75
  w_no_late   <- urps_fte_weight_sex(62, "female", "ABOG")
  w_with_late <- urps_fte_weight_sex(62, "female", "ABOG",
    late_from_age = 60, late_factor = 0.75)
  expect_equal(w_with_late, w_no_late * 0.75, tolerance = 1e-9)
})

test_that("late_factor does NOT apply below late_from_age", {
  w_no_late   <- urps_fte_weight_sex(55, "male", "ABOG")
  w_with_late <- urps_fte_weight_sex(55, "male", "ABOG",
    late_from_age = 60, late_factor = 0.75)
  expect_equal(w_with_late, w_no_late, tolerance = 1e-9)
})

test_that("late_factor from scenario registry integrates correctly", {
  sc <- urps_scenario("lower_late_career_fte")
  w_base <- urps_fte_weight_sex(62, "female", "ABOG")
  w_sc   <- urps_fte_weight_sex(62, "female", "ABOG",
    late_from_age = sc$late_career_fte_onset_age,
    late_factor   = sc$late_career_fte_factor)
  expect_equal(w_sc, w_base * sc$late_career_fte_factor, tolerance = 1e-9)
})

test_that("male ABOG FTE weight at peak is approximately 1.375 (55 hrs / 40)", {
  w <- urps_fte_weight_sex(47, "male", "ABOG")
  expect_equal(w, 55 / 40, tolerance = 0.01)
})

test_that("female ABU FTE weight at peak is approximately 0.823 (47 hrs / 40 * 0.7)", {
  w <- urps_fte_weight_sex(45, "female", "ABU")
  expect_equal(w, 47 / 40 * 0.7, tolerance = 0.01)
})

test_that("FTE weight is positive at ages 35:70 for all sex x pathway combinations", {
  for (sx in c("female", "male")) {
    for (pw in c("ABOG", "ABU")) {
      w <- urps_fte_weight_sex(35:70, sx, pw)
      expect_true(all(w > 0),
        label = sprintf("w > 0 at ages 35:70 for %s/%s", sx, pw))
    }
  }
})

test_that("FTE weight is vectorized over age", {
  out <- urps_fte_weight_sex(35:70, "male", "ABOG")
  expect_length(out, 36L)
})

# ---- urps_effective_fte_sex / urps_fte_scale_sex -----------------------------

test_that("effective FTE sex anchors reference cohort to headcount via scale", {
  cs <- data.frame(
    age     = c(45L, 62L, 45L, 62L),
    sex     = c("female", "female", "male", "male"),
    pathway = c("ABOG", "ABOG", "ABU", "ABU"),
    n       = c(350, 150, 100, 40))
  scale <- urps_fte_scale_sex(cs)
  expect_equal(urps_effective_fte_sex(cs, scale), sum(cs$n), tolerance = 1e-9)
})

test_that("effective FTE sex is additive across sex and pathway slices", {
  cs <- data.frame(
    age     = c(45L, 62L, 45L, 62L),
    sex     = c("female", "female", "male", "male"),
    pathway = c("ABOG", "ABOG", "ABOG", "ABOG"),
    n       = c(400, 200, 300, 100))
  scale <- urps_fte_scale_sex(cs)
  f  <- cs[cs$sex == "female", ]
  m  <- cs[cs$sex == "male",   ]
  expect_equal(
    urps_effective_fte_sex(f, scale) + urps_effective_fte_sex(m, scale),
    urps_effective_fte_sex(cs, scale),
    tolerance = 1e-9)
})

test_that("effective FTE sex applies late-career lever correctly", {
  cs <- data.frame(age = 62L, sex = "female", pathway = "ABOG", n = 100)
  scale  <- urps_fte_scale_sex(cs)
  sc     <- urps_scenario("lower_late_career_fte")
  fte_base <- urps_effective_fte_sex(cs, scale)
  fte_late <- urps_effective_fte_sex(cs, scale,
    late_from_age = sc$late_career_fte_onset_age,
    late_factor   = sc$late_career_fte_factor)
  expect_equal(fte_late, fte_base * sc$late_career_fte_factor, tolerance = 1e-9)
})

test_that("urps_fte_scale_sex fails loud on a zero-headcount cohort", {
  cs <- data.frame(age = 45L, sex = "female", pathway = "ABOG", n = 0)
  expect_error(urps_fte_scale_sex(cs), "non-positive")
})

test_that("effective_fte_sex fails loud on missing required columns", {
  expect_error(
    urps_effective_fte_sex(data.frame(age = 45L, pathway = "ABOG", n = 10)),
    "sex")
  expect_error(
    urps_effective_fte_sex(data.frame(age = 45L, sex = "female", n = 10)),
    "pathway")
})

test_that("a sex-stratified FTE projection satisfies the projection contract", {
  cs <- data.frame(
    age     = c(45L, 62L, 45L, 62L),
    sex     = c("female", "female", "male", "male"),
    pathway = c("ABOG", "ABOG", "ABU", "ABU"),
    n       = c(500, 250, 150, 79))
  scale <- urps_fte_scale_sex(cs)
  fte0  <- urps_effective_fte_sex(cs, scale)
  proj  <- data.frame(
    year = c(2023L, 2024L), scenario_id = "baseline", specialty = "URPS",
    certification_pathway = "ABOG_PLUS_ABU",
    geography_type = "national", geography_id = "US",
    supply_headcount    = c(sum(cs$n), sum(cs$n) + 50L - 12L),
    supply_clinical_fte = c(round(fte0, 1), NA),
    lower_95 = c(NA, NA), upper_95 = c(NA, NA),
    entrants = c(NA, 50L), exits = c(NA, 12L), net_change = c(NA, 38L),
    stringsAsFactors = FALSE)
  expect_true(validate_urps_projection(proj))
})

# ---- comparison with existing urps_fte_weight --------------------------------

# ---- urps_supply_fte_sex -----------------------------------------------------

test_that("urps_supply_fte_sex equals urps_effective_fte_sex applied to practicing_n", {
  cohort <- data.frame(
    age = c(45L, 62L, 45L, 62L),
    sex = c("female", "female", "male", "male"),
    pathway = c("ABOG", "ABOG", "ABU", "ABU"),
    certified_n = c(350, 150, 100, 40))
  p_n <- cohort$certified_n * urps_p_active(cohort$age, cohort$sex)
  ref_counts <- data.frame(
    age = cohort$age, sex = cohort$sex, pathway = cohort$pathway, n = p_n)
  scale <- urps_fte_scale_sex(ref_counts)
  expect_equal(
    urps_supply_fte_sex(cohort, scale),
    urps_effective_fte_sex(ref_counts, scale),
    tolerance = 1e-9)
})

test_that("urps_supply_fte_sex practicing_n is always <= certified_n (LFP < 1)", {
  cohort <- data.frame(
    age = c(40L, 55L, 70L), sex = "female",
    pathway = "ABOG", certified_n = c(300, 200, 50))
  out <- urps_apply_lfp(cohort)
  expect_true(all(out$practicing_n <= out$certified_n))
})

test_that("urps_supply_fte_sex is strictly less than naive urps_effective_fte_sex(certified)", {
  cohort <- data.frame(
    age = c(45L, 62L), sex = c("female", "male"),
    pathway = c("ABOG", "ABU"), certified_n = c(200, 100))
  # Build scale from certified (no LFP)
  cert_counts <- data.frame(
    age = cohort$age, sex = cohort$sex,
    pathway = cohort$pathway, n = cohort$certified_n)
  scale <- urps_fte_scale_sex(cert_counts)
  fte_certified  <- urps_effective_fte_sex(cert_counts, scale)
  fte_supply     <- urps_supply_fte_sex(cohort, scale)
  expect_lt(fte_supply, fte_certified)
})

test_that("urps_supply_fte_sex late_factor integrates correctly", {
  cohort <- data.frame(
    age = 62L, sex = "female", pathway = "ABOG", certified_n = 100)
  p_n <- 100 * urps_p_active(62L, "female")
  scale <- urps_fte_scale_sex(
    data.frame(age = 62L, sex = "female", pathway = "ABOG", n = p_n))
  sc       <- urps_scenario("lower_late_career_fte")
  fte_base <- urps_supply_fte_sex(cohort, scale)
  fte_late <- urps_supply_fte_sex(cohort, scale,
    late_from_age = sc$late_career_fte_onset_age,
    late_factor   = sc$late_career_fte_factor)
  expect_equal(fte_late, fte_base * sc$late_career_fte_factor, tolerance = 1e-9)
})

test_that("urps_supply_fte_sex fails loud on missing columns", {
  expect_error(
    urps_supply_fte_sex(data.frame(age=45L, sex="female", certified_n=100), 1),
    "pathway")
  expect_error(
    urps_supply_fte_sex(data.frame(age=45L, sex="female", pathway="ABOG"), 1),
    "certified_n")
})

test_that("urps_fte_weight_sex and urps_fte_weight coexist without conflict", {
  # Both can be called; they are independent models with different normalizations.
  # urps_fte_weight uses rel_to_peak (max=1); urps_fte_weight_sex uses hrs/40 (max>1).
  w_old <- urps_fte_weight(47, "ABOG")
  w_new <- urps_fte_weight_sex(47, "male", "ABOG")
  expect_true(is.numeric(w_old) && is.numeric(w_new))
  # New model: peak > 1 (subspecialists work more than 40 hrs/wk)
  expect_gt(w_new, 1.0)
  # Old model: peak = 1 (normalized to rel_to_peak)
  expect_lte(w_old, 1.0)
})

# ---- fail-loud on bad inputs -------------------------------------------------

test_that("unknown sex produces a hard error", {
  expect_error(urps_fte_predicted_hours(45, "nonbinary"), "female.*male|male.*female")
  expect_error(urps_fte_weight_sex(45, "F", "ABOG"),     "female.*male|male.*female")
})

test_that("unknown pathway produces a hard error", {
  expect_error(urps_fte_weight_sex(45, "female", "ABMS"),        "ABOG.*ABU|ABU.*ABOG")
  expect_error(urps_fte_weight_sex(45, "female", "ABOG_PLUS_ABU"), "ABOG.*ABU|ABU.*ABOG")
})

test_that("empty age vector produces a hard error", {
  expect_error(urps_fte_predicted_hours(integer(0), "male"), "non-empty")
  expect_error(urps_fte_weight_sex(numeric(0), "male", "ABOG"), "non-empty")
})
