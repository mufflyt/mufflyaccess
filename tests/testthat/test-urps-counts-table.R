library(testthat)
library(mufflyaccess)
test_that("urps_counts returns the complete canonical table", {
  counts <- urps_counts()
  required_columns <- c("year","abog_active","abu_net_new","combined_active",
                        "measure_year","snapshot_date","method_version","source_sha256")
  expect_s3_class(counts, "data.frame")
  expect_true(all(required_columns %in% names(counts)))
  expect_setequal(counts$year, 2013:2023)
  expect_false(as.logical(anyDuplicated(counts$year)))
})
test_that("all combined counts equal ABOG plus ABU net-new", {
  counts <- urps_counts()
  expect_equal(counts$combined_active, counts$abog_active + counts$abu_net_new)
})
test_that("2023 table values match the public accessor", {
  counts <- urps_counts()
  row_2023 <- counts[counts$year == 2023L, ]
  expect_equal(nrow(row_2023), 1L)
  expect_equal(row_2023$abog_active, urps_count(2023L, include_urology = FALSE))
  expect_equal(row_2023$combined_active, urps_count(2023L, include_urology = TRUE))
})
test_that("measure year is not confused with snapshot date", {
  counts <- urps_counts()
  expect_true(inherits(counts$snapshot_date, "Date"))
  expect_equal(counts$measure_year, counts$year)
  expect_true(all(as.integer(format(counts$snapshot_date, "%Y")) >= counts$measure_year))
})
