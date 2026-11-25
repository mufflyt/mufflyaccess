# Adversarial tests for RNG-state preservation in seeded helpers.
# The bug: a bare set.seed(seed) inside a helper silently rewound the caller's
# RNG stream, so repeated calls left .Random.seed in the same post-draw state
# and any ambient sampling afterwards was a deterministic replay.

library(testthat)

test_that("adversarial: mc_weighted_ci leaves the caller's RNG stream untouched", {
  set.seed(999)
  before <- .Random.seed
  invisible(mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0.5, 0.5), B = 100))
  expect_identical(.Random.seed, before)
})

test_that("adversarial: consecutive ambient draws are not a deterministic replay", {
  # The corruption signature: sample, call the helper, sample again -- before
  # the fix the two ambient samples were identical for default-seeded calls.
  set.seed(123)
  x1 <- stats::rnorm(5)
  invisible(mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0.5, 0.5), B = 100))
  x2 <- stats::rnorm(5)
  expect_false(identical(x1, x2))
  # and the stream matches what it would have been with no intervening call
  set.seed(123)
  y1 <- stats::rnorm(5)
  y2 <- stats::rnorm(5)
  expect_equal(x1, y1)
  expect_equal(x2, y2)
})

test_that("adversarial: mc_weighted_ci stays reproducible despite state restoration", {
  a <- mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0.5, 0.5), B = 200, seed = 1L)
  b <- mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0.5, 0.5), B = 200, seed = 1L)
  expect_identical(a, b)
  c2 <- mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0.5, 0.5), B = 200, seed = 2L)
  expect_false(identical(a, c2))
})

test_that("adversarial: no .Random.seed is fabricated when the caller had none", {
  if (exists(".Random.seed", envir = .GlobalEnv)) rm(".Random.seed", envir = .GlobalEnv)
  invisible(mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0.5, 0.5), B = 50))
  expect_false(exists(".Random.seed", envir = .GlobalEnv))
  set.seed(1)  # restore a sane stream for subsequent tests
})

test_that("adversarial: urps_ci_param_draw preserves caller RNG state when seeded", {
  set.seed(42)
  before <- .Random.seed
  invisible(urps_ci_param_draw(seed = 7L))
  expect_identical(.Random.seed, before)
  # reproducibility of the draw itself is preserved
  expect_identical(urps_ci_param_draw(seed = 42L), urps_ci_param_draw(seed = 42L))
  # NULL seed is the ambient-stream escape hatch and MUST advance the stream
  set.seed(5)
  before <- .Random.seed
  invisible(urps_ci_param_draw())
  expect_false(identical(.Random.seed, before))
})

test_that("adversarial: nested seeded calls cannot corrupt each other", {
  # Two different seeds back-to-back: both results reproducible regardless of
  # what the ambient stream was, and the ambient stream survives both.
  set.seed(2024)
  before <- .Random.seed
  a1 <- urps_ci_param_draw(seed = 1L)
  a2 <- urps_ci_param_draw(seed = 2L)
  expect_identical(.Random.seed, before)
  expect_identical(a1, urps_ci_param_draw(seed = 1L))
  expect_identical(a2, urps_ci_param_draw(seed = 2L))
})
