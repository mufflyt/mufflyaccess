test_that("safe_divide: zero/NA denom -> default, not Inf/NaN", {
  expect_true(is.na(safe_divide(1, 0)))
  expect_equal(safe_divide(1, 0, default = 0), 0)
  expect_equal(safe_divide(10, 2), 5)
  expect_equal(safe_divide(c(1, 2), c(0, 2)), c(NA, 1))
  expect_true(is.na(safe_divide(1, NA)))
})
test_that("safe_percent/rate/ratio wrappers", {
  expect_equal(safe_percent(1, 4), 25)
  expect_equal(safe_percent(1, 0), 0) # default 0
  expect_equal(safe_rate(2, 1000, multiplier = 100000), 200)
  expect_true(is.na(safe_rate(2, 0)))
  expect_equal(safe_ratio(3, 2), 1.5)
  expect_true(is.na(safe_pct_manu(1, 0))) # NA (not 0) per DEN-032
})

# A character argument used to be coerced with suppressWarnings(as.numeric()),
# so safe_divide("abc", 5) returned NA -- the same value a legitimate zero
# denominator produces. A count column read as text divided to "missing" and
# read downstream as suppressed-or-absent data, which is the exact failure this
# family exists to prevent.
test_that("safe_divide() rejects non-numeric input instead of coercing it", {
  expect_error(safe_divide("10", 5), "must be numeric")
  expect_error(safe_divide(10, "5"), "must be numeric")
  expect_error(safe_divide("abc", 5), "must be numeric")

  # Factors are the dangerous case: as.numeric() on a factor returns LEVEL
  # CODES, so the old path did not even produce NA -- it produced a confident
  # wrong number. factor("3") has one level, so it silently divided as 1.
  expect_error(safe_divide(factor("3"), 1), "must be numeric")
  expect_error(safe_divide(1, factor("3")), "must be numeric")

  # The error names the offending argument, so a stack of nested rate helpers
  # says which one was wrong.
  expect_error(safe_divide("10", 5), "numerator")
  expect_error(safe_divide(10, "5"), "denominator")
})

test_that("safe_divide() still accepts everything it accepted before", {
  # Logical must stay legal: a bare NA is logical, and safe_divide(1, NA)
  # returning the default is the contract every caller relies on.
  expect_true(is.na(safe_divide(1, NA)))
  expect_true(is.na(safe_divide(NA, 1)))
  expect_equal(safe_divide(TRUE, 2), 0.5)
  expect_equal(safe_divide(1L, 2L), 0.5)

  # NULL and zero-length are unchanged.
  expect_true(is.na(safe_divide(NULL, 4)))
  expect_true(is.na(safe_divide(4, NULL)))
  expect_length(safe_divide(integer(0), integer(0)), 0)

  # The wrappers inherit the validation through the primitive.
  expect_error(safe_percent("1", 4), "must be numeric")
  expect_error(safe_rate("1", 4), "must be numeric")
  expect_error(safe_ratio("1", 4), "must be numeric")
  expect_error(safe_pct_manu("1", 4), "must be numeric")
  expect_error(safe_divide_manu("1", 4), "must be numeric")
})
