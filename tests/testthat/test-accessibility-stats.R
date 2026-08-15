test_that("weighted_mean_all: weighted mean + zero-weight guard", {
  expect_equal(weighted_mean_all(c(1, 3), c(10, 30)), 2.5)
  expect_true(is.na(weighted_mean_all(c(5, 5), c(0, 0))))
})
test_that("zero_access_share: percent with EXACT-zero rule", {
  expect_equal(zero_access_share(c(0, 2, 0), c(10, 10, 10)), 200 / 3)
  expect_equal(zero_access_share(c(0.01, 5), c(50, 50)), 0)
})
test_that("mc_weighted_ci: point estimate lies inside its own interval", {
  acc <- c(2, 0, 5)
  est <- c(500, 20, 800)
  se <- c(60, 15, 90) / 1.645
  ci <- mc_weighted_ci(acc, est, se, stat = "mean", B = 500)
  expect_true(ci[["lo"]] <= ci[["point"]] && ci[["point"]] <= ci[["hi"]])
})
test_that("rurality_from_ruca derives the RUCA_NONMETRO_MIN boundary", {
  expect_equal(
    unname(rurality_from_ruca(c(1, 3, 4, 10, 99, NA))),
    c("Metropolitan", "Metropolitan", "Rural", "Rural", NA, NA)
  )
})
test_that("acs_year_of clamps to [2013,2022]; tract_vintage_of cuts at 2020", {
  expect_equal(acs_year_of(c(2011, 2013, 2020, 2023, 2030)), c(2013L, 2013L, 2020L, 2022L, 2022L))
  expect_equal(tract_vintage_of(c(2013, 2019, 2020, 2023)), c(2010, 2010, 2020, 2020))
})
test_that("annual_trend returns slope+CI+p; <3 pts -> NA", {
  t <- annual_trend(2013:2022, c(10, 11, 10, 12, 13, 12, 14, 15, 14, 16))
  expect_true(t[["slope"]] > 0 && is.finite(t[["p"]]))
  expect_true(all(is.na(annual_trend(2013:2014, c(1, 2)))))
})
test_that("ACS var codes: _026 full-table vs _017 race-table footgun", {
  expect_identical(TOTAL_FEMALE_VAR, "B01001_026")
  expect_true(all(grepl("_017$", RACE_FEMALE_VARS)))
})
