library(testthat)
library(mufflyaccess)
test_that("the bundled URPS SSOT passes validation", {
  result <- validate_urps_ssot()
  expect_true(isTRUE(result))
})
test_that("validation detects an altered count", {
  counts <- urps_counts()
  counts$combined_active[counts$year == 2023L] <- 1340L
  expect_error(validate_urps_ssot(counts), "combined|reconcile|1339|validation")
})
test_that("validation detects duplicate years", {
  counts <- urps_counts()
  counts <- rbind(counts, counts[counts$year == 2023L, ])
  expect_error(validate_urps_ssot(counts), "duplicate|unique")
})
test_that("validation detects missing years", {
  counts <- subset(urps_counts(), year != 2018L)
  expect_error(validate_urps_ssot(counts), "2018|missing|2013.*2023")
})
test_that("validation detects malformed hashes", {
  counts <- urps_counts()
  counts$source_sha256 <- "not-a-hash"
  expect_error(validate_urps_ssot(counts), "sha256|hash")
})
