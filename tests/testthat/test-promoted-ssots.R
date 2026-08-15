test_that("ACS MOE z constants match the isochrones SSOT", {
  expect_equal(ACS_MOE_Z90, 1.645)
  expect_equal(CI_Z95, 1.96)
  expect_identical(MOE90_TO_CI95_FACTOR, CI_Z95 / ACS_MOE_Z90)
  expect_equal(MOE90_TO_CI95_FACTOR, 1.96 / 1.645)
  expect_false(isTRUE(all.equal(ACS_MOE_Z90, qnorm(0.95)))) # rounded convention, NOT qnorm
})
test_that("RUCA_NONMETRO_MIN is the 2-level metro/rural cut", {
  expect_identical(RUCA_NONMETRO_MIN, 4L)
  expect_false(RUCA_NONMETRO_MIN == 7L) # not the 3-level suburban/rural split
})
test_that("Wu-2014 PFD prevalence table + accessors", {
  expect_equal(pfd_prevalence("any_PFD"), c(`65_79` = 0.368, `80plus` = 0.497))
  expect_equal(unname(pfd_prevalence("POP")), c(0.047, 0.040))
  expect_error(pfd_prevalence("nope"))
  b <- pfd_prevalence_acs_bands("any_PFD")
  expect_length(b, 6L)
  expect_equal(unname(b[["a65_66E"]]), 0.368)
  expect_equal(unname(b[["a85pE"]]), 0.497)
  # this is the Wu 65+ table, NOT the Nygaard all-ages one (no age<20 / 20-39 rows)
  expect_true(all(WU2014_PFD_PREVALENCE$p_65_79 > 0))
})

# URPS workforce counts are covered by the SSOT contract tests
# (test-urps-count.R, test-urps-counts-table.R, test-validate-urps-ssot.R,
# test-deprecated-urps-constants.R). The old frozen-constant assertions were
# removed when the constants were deprecated to warn-on-access active bindings.
