library(testthat)
library(mufflyaccess)
test_that("use_urps_artifact reads + validates an external artifact directory", {
  ext <- file.path(tempdir(), "urps_ext")
  dir.create(ext, showWarnings = FALSE)
  bundled <- system.file("extdata", package = "mufflyaccess")
  file.copy(file.path(bundled, "urps_counts_by_year.csv"),
    file.path(ext, "urps_counts_by_year.csv"),
    overwrite = TRUE
  )
  m <- jsonlite::read_json(file.path(bundled, "urps_manifest.json"), simplifyVector = TRUE)
  fake_commit <- paste(rep("a", 40), collapse = "")
  m$git_commit <- fake_commit
  jsonlite::write_json(m, file.path(ext, "urps_manifest.json"), auto_unbox = TRUE, pretty = TRUE)
  on.exit(use_urps_artifact(NULL), add = TRUE)
  suppressMessages(use_urps_artifact(ext))
  expect_identical(urps_provenance()$source_git_commit, fake_commit) # external manifest served
  expect_equal(urps_count(2023L, include_urology = TRUE), 1306L)
  expect_equal(urps_provenance()$artifact_source, "external")
  suppressMessages(use_urps_artifact(NULL))
  expect_false(identical(urps_provenance()$source_git_commit, fake_commit)) # back to bundled
})
test_that("use_urps_artifact rejects a missing directory (fails closed)", {
  before <- getOption("mufflyaccess.urps_artifact_dir")
  expect_error(use_urps_artifact(file.path(tempdir(), "no_such_urps_dir_xyz")))
  expect_identical(getOption("mufflyaccess.urps_artifact_dir"), before)
})
