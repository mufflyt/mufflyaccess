library(testthat)
library(mufflyaccess)
test_that("urps_count returns the canonical 2023 ABOG count", {
  result <- urps_count(year = 2023L, include_urology = FALSE)
  expect_equal(result, 1031L)
  expect_type(result, "integer")
})
test_that("urps_count returns the canonical 2023 combined active count (1332, not 1339)", {
  result <- urps_count(year = 2023L, include_urology = TRUE)
  expect_equal(result, 1332L)          # 1339 is the 2025 roster snapshot, not 2023 active
  expect_type(result, "integer")
})
test_that("adding urology contributes exactly 301 providers in 2023", {
  without_urology <- urps_count(year = 2023L, include_urology = FALSE)
  with_urology <- urps_count(year = 2023L, include_urology = TRUE)
  expect_equal(with_urology - without_urology, 301L)   # NOT 308 (that is the roster increment)
})
test_that("urps_count accepts only one valid year", {
  expect_error(urps_count(year = c(2022L, 2023L)), "single")
  expect_error(urps_count(year = NA_integer_), "year")
  expect_error(urps_count(year = "2023"), "integer|numeric|year")
})
test_that("urps_count rejects unavailable years", {
  expect_error(urps_count(year = 2012L), "available|2013|unsupported")
  expect_error(urps_count(year = 2024L), "available|2023|unsupported")
})
test_that("include_urology must be a nonmissing scalar logical", {
  expect_error(urps_count(year = 2023L, include_urology = NA), "include_urology")
  expect_error(urps_count(year = 2023L, include_urology = c(TRUE, FALSE)), "include_urology|single")
  expect_error(urps_count(year = 2023L, include_urology = 1), "logical")
})
