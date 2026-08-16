# Direct coverage for exported functions that no other test file referenced by
# name: get_canonical_bands() (access-band accessor), safe_divide_manu() (a
# manuscript-facing safe-division member), and compare_urps_artifacts()
# (release-to-release drift diff). These are on the public surface, so they carry
# a contract even when nothing internally happens to exercise them.

test_that("get_canonical_bands() returns the canonical band vector", {
  b <- get_canonical_bands()
  expect_identical(b, CANONICAL_BANDS) # accessor === the constant
  expect_true(is.numeric(b))
  expect_identical(b, sort(b)) # strictly increasing
  expect_false(anyDuplicated(b) > 0)
  expect_true(all(b > 0))
})

test_that("safe_divide_manu() divides, and falls back on a zero/invalid denominator", {
  expect_equal(safe_divide_manu(10, 2), 5)
  expect_equal(safe_divide_manu(c(6, 9), c(2, 3)), c(3, 3)) # vectorised
  # zero denominator -> the fallback, not Inf
  expect_true(is.na(safe_divide_manu(1, 0)))
  expect_false(is.infinite(safe_divide_manu(1, 0)))
  # custom fallback is honoured
  expect_identical(safe_divide_manu(1, 0, fallback = -1), -1)
  # element-wise: only the zero-denominator element takes the fallback
  expect_equal(safe_divide_manu(c(4, 4), c(2, 0), fallback = 0), c(2, 0))
})

test_that("compare_urps_artifacts() reports no count drift between identical releases", {
  old <- copy_urps_fixture()
  cand <- copy_urps_fixture()
  drift <- compare_urps_artifacts(old, cand)
  expect_type(drift, "list")
  expect_length(drift$changed_counts, 0) # identical bytes -> no diff
})

test_that("compare_urps_artifacts() flags a changed count cell", {
  old <- copy_urps_fixture()
  cand <- copy_urps_fixture()
  # bump exactly one count cell in the candidate
  mutate_counts(cand, function(d) {
    i <- which(d$year == 2023 & d$measure == "board_certified_active" &
      d$geography == "national" & d$board_pathway == "ABOG")[1]
    d$n_active[i] <- d$n_active[i] + 7L
    d
  })
  drift <- compare_urps_artifacts(old, cand)
  expect_gte(length(drift$changed_counts), 1)
  expect_true(any(grepl(
    "2023\\|board_certified_active\\|national\\|ABOG",
    drift$changed_counts
  )))
})
