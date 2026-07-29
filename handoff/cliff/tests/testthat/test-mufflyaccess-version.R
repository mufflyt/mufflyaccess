# [APPLY IN: cliff]
library(testthat)
test_that("cliff uses an approved mufflyaccess version", {
  skip_if_not_installed("mufflyaccess")
  expect_gte(utils::packageVersion("mufflyaccess"), package_version("0.1.0"))
})
test_that("mufflyaccess is recorded in renv.lock", {
  skip_if_not(file.exists("renv.lock"))
  lock <- jsonlite::read_json("renv.lock", simplifyVector = FALSE)
  expect_true("mufflyaccess" %in% names(lock$Packages),
    info = "mufflyaccess must be pinned in renv.lock rather than installed ad hoc")
  record <- lock$Packages$mufflyaccess
  expect_true(record$Source %in% c("GitHub","Repository"))
  if (identical(record$Source, "GitHub")) {
    expect_identical(record$RemoteUsername, "mufflyt")
    expect_identical(record$RemoteRepo, "mufflyaccess")
    expect_match(record$RemoteSha, "^[0-9a-f]{40}$")
  }
})
