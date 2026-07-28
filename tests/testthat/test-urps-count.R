test_that("urps_count returns reconciled headline values with the new API", {
  expect_equal(as.integer(urps_count(2023L, include_urology = FALSE)), 1031L)
  expect_equal(as.integer(urps_count(2023L, include_urology = TRUE)),  1339L)
  expect_equal(as.integer(urps_count()), 1031L)  # default: 2023, without urology
})

test_that("urps_count distinguishes the three years and carries provenance", {
  x <- urps_count(2023L, include_urology = TRUE)
  expect_identical(attr(x, "measure_year"), 2023L)
  expect_identical(attr(x, "snapshot_date"), "2026-07-22")
  expect_identical(attr(x, "model_baseline_year"), 2025L)
  expect_identical(attr(x, "board_pathway"), "abog_plus_abu")
  expect_true(nzchar(attr(x, "provenance")))
})

test_that("ABOG-only is a by-year series; with-urology is 2023-only", {
  expect_equal(as.integer(urps_count(2013L)), 843L)
  expect_error(urps_count(2013L, include_urology = TRUE), "2023 snapshot only")
  expect_error(urps_count(1999L), "no abog count")
})

test_that("urps_counts / urps_provenance / validate_urps_ssot behave", {
  tab <- urps_counts()
  expect_true(all(c("year","board_pathway","n_active","source_sha256") %in% names(tab)))
  expect_equal(nrow(subset(tab, board_pathway == "abog")), 11L)
  prov <- urps_provenance()
  expect_equal(prov$years$model_baseline_year, 2025L)
  expect_equal(prov$headline_values_2023$abu_net_new, 308L)
  expect_true(validate_urps_ssot())
})
