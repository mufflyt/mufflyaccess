library(testthat)

# urps_lfp.R: logistic labor force participation model for URPS.

# ---- version -----------------------------------------------------------------

test_that("URPS_LFP_VERSION is semver", {
  expect_match(URPS_LFP_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

# ---- params table ------------------------------------------------------------

test_that("params table has required columns, 2 rows, and valid calibrated values", {
  d <- urps_lfp_params()
  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), 2L)
  expect_setequal(d$sex, c("female", "male"))
  expect_true(all(c("intercept", "b_age",
                    "anchor_age_lo", "anchor_p_lo",
                    "anchor_age_hi", "anchor_p_hi",
                    "calibration_status") %in% names(d)))
  expect_true(all(d$calibration_status == "calibrated_from_literature"))
  expect_true(all(d$b_age < 0))
})

test_that("params table carries source and formula attributes", {
  d <- urps_lfp_params()
  expect_false(is.null(attr(d, "source")))
  expect_match(attr(d, "formula"), "intercept")
})

test_that("no duplicate sex rows", {
  d <- urps_lfp_params()
  expect_equal(anyDuplicated(d$sex), 0L)
})

test_that("anchor_p_lo > anchor_p_hi (participation falls with age)", {
  d <- urps_lfp_params()
  expect_true(all(d$anchor_p_lo > d$anchor_p_hi))
})

test_that("anchor p values are in (0, 1)", {
  d <- urps_lfp_params()
  expect_true(all(d$anchor_p_lo > 0 & d$anchor_p_lo < 1))
  expect_true(all(d$anchor_p_hi > 0 & d$anchor_p_hi < 1))
})

# ---- urps_p_active: anchor reproduction --------------------------------------

test_that("female anchor points reproduce within 1e-6", {
  expect_equal(urps_p_active(40, "female"), 0.97, tolerance = 1e-6)
  expect_equal(urps_p_active(65, "female"), 0.78, tolerance = 1e-6)
})

test_that("male anchor points reproduce within 1e-6", {
  expect_equal(urps_p_active(40, "male"), 0.98, tolerance = 1e-6)
  expect_equal(urps_p_active(65, "male"), 0.85, tolerance = 1e-6)
})

# ---- urps_p_active: structural properties ------------------------------------

test_that("p_active is strictly in (0, 1) at plausible ages 25:90", {
  for (sx in c("female", "male")) {
    p <- urps_p_active(25:90, sx)
    expect_true(all(p > 0 & p < 1),
      label = paste("p in (0,1) for", sx))
  }
})

test_that("p_active is strictly decreasing with age (logistic with b_age < 0)", {
  for (sx in c("female", "male")) {
    p <- urps_p_active(35:80, sx)
    expect_true(all(diff(p) < 0),
      label = paste("p decreasing for", sx))
  }
})

test_that("male p_active exceeds female p_active at same age across career", {
  ages <- 35:70
  p_m <- urps_p_active(ages, "male")
  p_f <- urps_p_active(ages, "female")
  expect_true(all(p_m > p_f))
})

test_that("p_active approaches 1 at young ages and is well below 1 at old ages", {
  expect_gt(urps_p_active(30, "female"), 0.97)
  expect_gt(urps_p_active(30, "male"),   0.98)
  expect_lt(urps_p_active(80, "female"), 0.65)
  expect_lt(urps_p_active(80, "male"),   0.72)
})

# ---- urps_p_active: vectorization --------------------------------------------

test_that("p_active is vectorized over age", {
  out <- urps_p_active(35:75, "female")
  expect_length(out, 41L)
  expect_equal(
    urps_p_active(c(40, 50, 65), "male"),
    c(urps_p_active(40, "male"),
      urps_p_active(50, "male"),
      urps_p_active(65, "male"))
  )
})

test_that("p_active is vectorized over sex (mixed-sex cohort)", {
  ages  <- c(45L, 55L)
  sexes <- c("female", "male")
  out   <- urps_p_active(ages, sexes)
  expect_length(out, 2L)
  expect_equal(out[1], urps_p_active(45, "female"))
  expect_equal(out[2], urps_p_active(55, "male"))
})

test_that("scalar sex recycled over age vector", {
  out_f <- urps_p_active(40:50, "female")
  ref   <- vapply(40:50, function(a) urps_p_active(a, "female"), numeric(1))
  expect_equal(out_f, ref)
})

# ---- urps_lfp_curve ----------------------------------------------------------

test_that("urps_lfp_curve returns data.frame with correct structure", {
  curve <- urps_lfp_curve("female")
  expect_s3_class(curve, "data.frame")
  expect_setequal(names(curve), c("age", "p_active"))
  expect_equal(nrow(curve), length(35:80))
  expect_equal(curve$age, as.integer(35:80))
})

test_that("urps_lfp_curve respects a custom age_range", {
  curve <- urps_lfp_curve("male", age_range = 40:70)
  expect_equal(nrow(curve), 31L)
  expect_equal(curve$age, as.integer(40:70))
})

test_that("urps_lfp_curve values match urps_p_active directly", {
  curve <- urps_lfp_curve("female", age_range = 40:70)
  expect_equal(curve$p_active, urps_p_active(40:70, "female"))
})

test_that("p_active in curve is strictly decreasing for both sexes", {
  for (sx in c("female", "male")) {
    curve <- urps_lfp_curve(sx)
    expect_true(all(diff(curve$p_active) < 0),
      label = paste("decreasing p_active in curve for", sx))
  }
})

# ---- intermediate values (spot checks) ---------------------------------------

test_that("implied mid-career participation values are plausible", {
  # Female: P(50) expected ~0.930, P(60) ~0.847
  expect_gt(urps_p_active(50, "female"), 0.90)
  expect_lt(urps_p_active(50, "female"), 0.97)
  expect_gt(urps_p_active(60, "female"), 0.78)
  expect_lt(urps_p_active(60, "female"), 0.97)
  # Male: P(50) expected ~0.954, P(60) ~0.897
  expect_gt(urps_p_active(50, "male"), 0.93)
  expect_lt(urps_p_active(50, "male"), 0.98)
  expect_gt(urps_p_active(60, "male"), 0.85)
  expect_lt(urps_p_active(60, "male"), 0.98)
})

# ---- fail-loud on bad inputs -------------------------------------------------

test_that("unknown sex produces a hard error", {
  expect_error(urps_p_active(45, "nonbinary"), "female.*male|male.*female")
  expect_error(urps_p_active(45, "F"),         "female.*male|male.*female")
  expect_error(urps_lfp_curve("Male"),         "female.*male|male.*female")
})

test_that("empty age vector produces a hard error", {
  expect_error(urps_p_active(integer(0), "female"), "non-empty")
  expect_error(urps_p_active(numeric(0), "male"),   "non-empty")
})

test_that("non-numeric age produces a hard error", {
  expect_error(urps_p_active("forty", "female"), "numeric")
})

test_that("empty age_range in urps_lfp_curve produces a hard error", {
  expect_error(urps_lfp_curve("female", age_range = integer(0)), "non-empty")
})
