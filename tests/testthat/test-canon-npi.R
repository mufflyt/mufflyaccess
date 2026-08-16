# canon_npi: the SSOT NPI normalizer promoted from isochrones. These assertions
# pin the exact behavior consumers rely on (leading-zero-safe, overflow-safe,
# fail-closed on garbage) so a future edit cannot silently weaken it.

test_that("valid 10-digit NPIs pass through unchanged", {
  expect_equal(canon_npi("1234567893", verbose = FALSE), "1234567893")
  expect_equal(
    canon_npi(c("1992998967", "1326161225"), verbose = FALSE),
    c("1992998967", "1326161225")
  )
})

test_that("separators are stripped", {
  expect_equal(canon_npi("12-3456 7890", verbose = FALSE), "1234567890")
  expect_equal(canon_npi("123.456.7890", verbose = FALSE), "1234567890")
})

test_that("short digit strings are left-zero-padded to 10 (no leading-zero loss)", {
  expect_equal(canon_npi("5", verbose = FALSE), "0000000005")
  expect_equal(canon_npi("123", verbose = FALSE), "0000000123")
  # the numeric-coercion footgun this replaces: as.integer(1234567890) is fine,
  # but sprintf("%.0f", 5) -> "5" (no pad); canon_npi pads correctly.
})

test_that("numeric input is handled without scientific-notation corruption", {
  expect_equal(canon_npi(1234567893, verbose = FALSE), "1234567893")
})

test_that("garbage fails closed to NA", {
  expect_true(is.na(canon_npi("abc", verbose = FALSE)))
  expect_true(is.na(canon_npi("12ab34", verbose = FALSE))) # letters
  expect_true(is.na(canon_npi("123456789012", verbose = FALSE))) # too many digits
  expect_true(is.na(canon_npi("1.2e9", verbose = FALSE))) # scientific notation
  expect_true(is.na(canon_npi(NA, verbose = FALSE)))
  expect_true(is.na(canon_npi("", verbose = FALSE)))
})

test_that("vectorized, length-preserving, NA-safe", {
  out <- canon_npi(c("1234567893", "abc", NA, "12-34 567890"), verbose = FALSE)
  expect_length(out, 4L)
  expect_equal(out, c("1234567893", NA, NA, "1234567890"))
})

test_that("NULL returns empty character; non-atomic errors", {
  expect_identical(canon_npi(NULL), character(0))
  expect_error(canon_npi(list(1, 2)), "atomic")
})
