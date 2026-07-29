library(testthat)
test_that("ambiguous 2025 constants are deprecated", {
  expect_warning(value_abog <- mufflyaccess::URPS_COUNT_ABOG_ONLY_2025,
                 "deprecated|urps_count")
  expect_warning(value_combined <- mufflyaccess::URPS_COUNT_ABOG_PLUS_ABU_2025,
                 "deprecated|urps_count")
  expect_equal(value_abog, 1031L)
  expect_equal(value_combined, 1339L)
})
