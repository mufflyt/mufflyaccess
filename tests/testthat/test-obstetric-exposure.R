# Obstetric exposure parameter series (R/obstetric_exposure.R).
#
# These series were byte-identical in two repos (parity anchors sha256
# 193aefef...) and are the primary exposure of the downstream pelvic-floor
# models, so the tests here are about the series staying the series: correct
# interpolation, clamping rather than extrapolation, and the anchors themselves
# not moving without someone noticing.

test_that("interpolation hits the anchors exactly", {
  par <- mufflyaccess:::.obstetric_extdata("us_completed_parity_by_cohort.csv")
  for (i in seq_len(nrow(par))) {
    expect_equal(completed_parity_for_cohort(par$birth_cohort[i]),
                 par$mean_completed_parity[i])
  }
})

test_that("outside the anchor range it CLAMPS rather than extrapolating", {
  # rule = 2. Linear extrapolation off the 1930-1982 parity anchors would run
  # completed parity negative within a couple of centuries and, more to the
  # point, produce a confidently wrong number for any cohort past the last
  # anchor -- which is every cohort the projection actually cares about.
  par <- mufflyaccess:::.obstetric_extdata("us_completed_parity_by_cohort.csv")
  lo <- min(par$birth_cohort); hi <- max(par$birth_cohort)
  expect_equal(completed_parity_for_cohort(lo - 50),
               par$mean_completed_parity[which.min(par$birth_cohort)])
  expect_equal(completed_parity_for_cohort(hi + 50),
               par$mean_completed_parity[which.max(par$birth_cohort)])
})

test_that("the parity series still says what it said when it was adopted", {
  # A regression guard on the DATA, not the code. The series is cited and these
  # anchors are quoted in downstream methods text; a silent edit here would
  # change the primary exposure of every model built on it.
  expect_equal(completed_parity_for_cohort(1930), 2.96)
  expect_equal(completed_parity_for_cohort(1955), 2.00)
  expect_equal(completed_parity_for_cohort(1982), 1.92)
})

test_that("the cesarean series interpolates and clamps the same way", {
  ces <- mufflyaccess:::.obstetric_extdata("us_cesarean_rate_by_year.csv")
  expect_equal(cesarean_rate_for_year(ces$year[1]), ces$cesarean_rate[1])
  expect_equal(cesarean_rate_for_year(min(ces$year) - 20),
               ces$cesarean_rate[which.min(ces$year)])
  expect_equal(cesarean_rate_for_year(max(ces$year) + 20),
               ces$cesarean_rate[which.max(ces$year)])
  expect_true(all(cesarean_rate_for_year(1970:2020) >= 0))
  expect_true(all(cesarean_rate_for_year(1970:2020) <= 1))
})

test_that("an injected series is used instead of the packaged one", {
  # The argument exists so the interpolation can be tested against a series
  # whose answer is known by construction, independent of the shipped anchors.
  fake <- data.frame(birth_cohort = c(1900, 2000), mean_completed_parity = c(0, 10))
  expect_equal(completed_parity_for_cohort(1950, par = fake), 5)
  fake_c <- data.frame(year = c(1900, 2000), cesarean_rate = c(0, 1))
  expect_equal(cesarean_rate_for_year(1950, ces = fake_c), 0.5)
})

test_that("a malformed series is rejected by name", {
  expect_error(completed_parity_for_cohort(1950, par = data.frame(a = 1)), "par")
  expect_error(cesarean_rate_for_year(1950, ces = data.frame(a = 1)), "ces")
})

test_that("cohort exposure splits parity into vaginal and cesarean", {
  e <- cohort_vaginal_exposure(c(1940, 1970))
  expect_equal(nrow(e), 2L)
  # The split is exhaustive: the two components reconstitute total parity.
  expect_equal(e$mean_vaginal_deliveries + e$mean_cesarean_deliveries,
               e$mean_total_parity, tolerance = 1e-3)
  expect_true(all(e$cohort_cesarean_fraction >= 0 & e$cohort_cesarean_fraction <= 1))
})

test_that("later cohorts carry a higher cesarean fraction", {
  # The whole reason the model tracks delivery mode by cohort: the US cesarean
  # rate rose sharply, so vaginal exposure falls for later cohorts even where
  # completed parity does not.
  e <- cohort_vaginal_exposure(c(1935, 1975))
  expect_gt(e$cohort_cesarean_fraction[2], e$cohort_cesarean_fraction[1])
})

test_that("cohort exposure averages over the childbearing window, not one year", {
  # A cohort's cesarean fraction must reflect its own fertile years. Reading a
  # single calendar year would attribute one year's obstetric practice to a
  # whole cohort.
  expect_equal(mufflyaccess:::OBSTETRIC_CHILDBEAR_AGE_LO, 20L)
  expect_equal(mufflyaccess:::OBSTETRIC_CHILDBEAR_AGE_HI, 35L)
  c0 <- 1960
  window <- mean(cesarean_rate_for_year((c0 + 20):(c0 + 35)))
  expect_equal(cohort_vaginal_exposure(c0)$cohort_cesarean_fraction,
               round(window, 4))
})

test_that("empty or NA cohorts are refused", {
  expect_error(cohort_vaginal_exposure(integer(0)), "non-empty")
  expect_error(cohort_vaginal_exposure(c(1950, NA)), "NA")
})
