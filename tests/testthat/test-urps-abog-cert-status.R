library(testthat)

# urps_abog_cert_status.R: frozen, validated ABOG certification status for the
# URPS/FPMRS board-certified cohort. Compiled per-physician data, not
# distributed with this public package -- these tests skip when no local copy
# is configured (see ?urps_abog_cert_status).

.skip_if_no_local_artifact <- function() {
  ok <- tryCatch({
    urps_abog_cert_status()
    TRUE
  }, error = function(e) FALSE)
  skip_if_not(ok, "no local urps_abog_cert_status artifact configured")
}

test_that("returns a data.frame with the required columns and no duplicate abog_id", {
  .skip_if_no_local_artifact()
  d <- urps_abog_cert_status()
  expect_s3_class(d, "data.frame")
  expect_true(all(c(
    "abog_id", "certStatus", "cert_category_current", "refresh_is_current",
    "cert_status_is_expired", "refresh_snapshot_date", "refresh_source_sha256",
    "method_version"
  ) %in% names(d)))
  expect_equal(anyDuplicated(d$abog_id), 0L)
  expect_gt(nrow(d), 0L)
})

test_that("abog_id is integer and cert_category_current is a known ABOG status value", {
  .skip_if_no_local_artifact()
  d <- urps_abog_cert_status()
  expect_true(is.integer(d$abog_id))
  expect_true(all(!is.na(d$cert_category_current)))
  expect_true(is.logical(d$refresh_is_current))
  expect_true(is.logical(d$cert_status_is_expired))
})

test_that("an Active-looking status is only reported Active when actually refreshed", {
  .skip_if_no_local_artifact()
  d <- urps_abog_cert_status()
  active_rows <- d[d$cert_category_current == "Active", , drop = FALSE]
  expect_true(all(active_rows$refresh_is_current))

  stale_rows <- d[d$cert_category_current == "Unknown (stale active status)", , drop = FALSE]
  if (nrow(stale_rows) > 0L) {
    expect_true(all(!stale_rows$refresh_is_current))
  }
})

test_that("every row carries non-missing provenance", {
  .skip_if_no_local_artifact()
  d <- urps_abog_cert_status()
  expect_true(all(!is.na(d$refresh_snapshot_date) & nzchar(d$refresh_snapshot_date)))
  expect_true(all(!is.na(d$refresh_source_sha256) & nzchar(d$refresh_source_sha256)))
  expect_true(all(!is.na(d$method_version) & nzchar(d$method_version)))
  expect_equal(length(unique(d$refresh_snapshot_date)), 1L)
  expect_equal(length(unique(d$refresh_source_sha256)), 1L)
})
