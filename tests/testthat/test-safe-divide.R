test_that("safe_divide: zero/NA denom -> default, not Inf/NaN", {
  expect_true(is.na(safe_divide(1, 0)))
  expect_equal(safe_divide(1, 0, default = 0), 0)
  expect_equal(safe_divide(10, 2), 5)
  expect_equal(safe_divide(c(1,2), c(0,2)), c(NA, 1))
  expect_true(is.na(safe_divide(1, NA)))
})
test_that("safe_percent/rate/ratio wrappers", {
  expect_equal(safe_percent(1, 4), 25)
  expect_equal(safe_percent(1, 0), 0)          # default 0
  expect_equal(safe_rate(2, 1000, multiplier = 100000), 200)
  expect_true(is.na(safe_rate(2, 0)))
  expect_equal(safe_ratio(3, 2), 1.5)
  expect_true(is.na(safe_pct_manu(1, 0)))      # NA (not 0) per DEN-032
})
