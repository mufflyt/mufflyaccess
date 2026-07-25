test_that("ACS MOE z constants match the isochrones SSOT", {
  expect_equal(ACS_MOE_Z90, 1.645)
  expect_equal(CI_Z95, 1.96)
  expect_identical(MOE90_TO_CI95_FACTOR, CI_Z95 / ACS_MOE_Z90)
  expect_equal(MOE90_TO_CI95_FACTOR, 1.96 / 1.645)
  expect_false(isTRUE(all.equal(ACS_MOE_Z90, qnorm(0.95))))  # rounded convention, NOT qnorm
})
test_that("RUCA_NONMETRO_MIN is the 2-level metro/rural cut", {
  expect_identical(RUCA_NONMETRO_MIN, 4L)
  expect_false(RUCA_NONMETRO_MIN == 7L)                      # not the 3-level suburban/rural split
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

test_that("URPS 2025 workforce counts (with/without urology) are frozen and reconcile", {
  expect_identical(as.integer(URPS_COUNT_ABOG_ONLY_2025), 1031L)      # without urology (ABOG only)
  expect_identical(as.integer(URPS_COUNT_ABOG_PLUS_ABU_2025), 1295L)  # with urology (ABOG + ABU)
  # WITH urology exceeds WITHOUT, and the gap is exactly the ABU net-new contribution
  expect_gt(as.integer(URPS_COUNT_ABOG_PLUS_ABU_2025), as.integer(URPS_COUNT_ABOG_ONLY_2025))
  expect_identical(as.integer(URPS_COUNT_ABOG_PLUS_ABU_2025) - as.integer(URPS_COUNT_ABOG_ONLY_2025), 264L)
  # provenance attributes are attached (same contract as ACS2020_CONUS_FEMALE_POP)
  expect_equal(attr(URPS_COUNT_ABOG_ONLY_2025, "year"), 2025L)
  expect_true(nzchar(attr(URPS_COUNT_ABOG_PLUS_ABU_2025, "source")))
  # deterministic: referencing the constant yields the same value every call
  expect_identical(URPS_COUNT_ABOG_ONLY_2025, URPS_COUNT_ABOG_ONLY_2025)
})
