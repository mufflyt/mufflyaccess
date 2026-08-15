library(testthat)
library(mufflyaccess)
test_that("bundled counts match the producer release contract (v3.0.0 shape)", {
  contract_path <- system.file("extdata", "urps_release_contract.json",
    package = "mufflyaccess"
  )
  expect_true(nzchar(contract_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = TRUE)
  expect_equal(contract$contract_version, "3.0.0")

  # canonical 2023 estimand = board_certified_active / national / ABOG_PLUS_ABU = 1306
  expect_equal(contract$canonical$n_active, 1306L)
  expect_equal(
    urps_count(2023, "board_certified_active", "national", TRUE),
    contract$canonical$n_active
  )

  bca <- contract$measures$board_certified_active
  expect_equal(urps_count(2023, "board_certified_active", "national", FALSE), bca$national$abog)
  expect_equal(urps_count(2023, "board_certified_active", "national", TRUE), bca$national$combined)
  expect_equal(urps_count(2023, "board_certified_active", "conus", TRUE), bca$conus$combined)
  expect_equal(bca$national$combined, bca$national$abog + bca$national$abu_net_new)
  expect_equal(bca$national$abog, 1027L)
  expect_equal(bca$national$abu_net_new, 279L)

  ros <- contract$measures$roster_snapshot
  expect_equal(urps_count(2025, "roster_snapshot", "national", TRUE), ros$national$combined)
  expect_equal(urps_count(2025, "roster_snapshot", "conus", TRUE), ros$conus$combined)
  expect_equal(ros$national$combined, 1339L)
})
