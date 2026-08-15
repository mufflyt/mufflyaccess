# Promoted SSOT primitives: standardize_state_name (identity) and the canonical
# hashers fingerprint_object / fingerprint_files (provenance).

test_that("standardize_state_name maps names/codes/territories both directions", {
  expect_equal(
    standardize_state_name(c("colorado", "TX", "Puerto Rico"), output = "abbr"),
    c("CO", "TX", "PR")
  )
  expect_equal(
    standardize_state_name(c("co", "tx"), output = "name"),
    c("Colorado", "Texas")
  )
  expect_equal(standardize_state_name("District of Columbia", output = "abbr"), "DC")
  expect_equal(standardize_state_name("dc", output = "name"), "District of Columbia")
})

test_that("standardize_state_name unmapped fallback + case/whitespace/dot cleaning", {
  expect_equal(standardize_state_name("  colorado ", output = "abbr"), "CO")
  expect_equal(standardize_state_name("D.C.", output = "abbr"), "DC")
  # unmapped -> title case for name, NA for abbr
  expect_equal(standardize_state_name("atlantis", output = "name"), "Atlantis")
  expect_true(is.na(standardize_state_name("atlantis", output = "abbr")))
})

test_that("standardize_state_name is pure: no message/print/side effects", {
  expect_silent(standardize_state_name(c("co", "tx"), output = "abbr"))
})

test_that("fingerprint_object is a stable 64-char sha256, sensitive to content", {
  h <- fingerprint_object(list(a = 1, b = "x"))
  expect_match(h, "^[0-9a-f]{64}$")
  expect_identical(h, fingerprint_object(list(a = 1, b = "x"))) # deterministic
  expect_false(identical(h, fingerprint_object(list(a = 2, b = "x"))))
})

test_that("fingerprint_files hashes content, is order-independent, NA when absent", {
  d <- withr::local_tempdir()
  f1 <- file.path(d, "a.R")
  f2 <- file.path(d, "b.R")
  writeLines("x <- 1", f1)
  writeLines("y <- 2", f2)
  h_ab <- fingerprint_files(c(f1, f2))
  h_ba <- fingerprint_files(c(f2, f1))
  expect_match(h_ab, "^[0-9a-f]{64}$")
  expect_identical(h_ab, h_ba) # sorted -> order-independent
  writeLines("x <- 999", f1)
  expect_false(identical(h_ab, fingerprint_files(c(f1, f2)))) # content-sensitive
  expect_true(is.na(fingerprint_files(file.path(d, "nope.R")))) # absent -> NA
})
