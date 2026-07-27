test_that("urps_count returns the reconciled SSOT values", {
  expect_equal(as.integer(urps_count("abog")), 1031L)
  expect_equal(as.integer(urps_count("abog_plus_abu")), 1339L)
  expect_equal(as.integer(urps_count()), 1339L)  # default = with urology
})

test_that("urps_count carries metadata + provenance and agrees with the constants", {
  x <- urps_count("abog_plus_abu")
  expect_identical(attr(x, "urology"), "with")
  expect_identical(attr(x, "definition"), "abog_plus_abu")
  expect_false(attr(x, "validated"))
  expect_true(nzchar(attr(x, "abog_snapshot_sha256")))
  expect_equal(as.integer(urps_count("abog")), as.integer(URPS_COUNT_ABOG_ONLY_2025))
  expect_equal(as.integer(urps_count("abog_plus_abu")), as.integer(URPS_COUNT_ABOG_PLUS_ABU_2025))
})

test_that("urps_count rejects an unknown definition and a missing snapshot", {
  expect_error(urps_count("nope"))
  expect_error(urps_count(snapshot = "/no/such/file.csv"), "not found")
})
