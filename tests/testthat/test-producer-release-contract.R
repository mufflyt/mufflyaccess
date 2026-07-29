library(testthat)
library(mufflyaccess)
test_that("bundled counts match the producer release contract", {
  contract_path <- system.file("extdata", "urps_release_contract.json",
                               package = "mufflyaccess")
  expect_true(nzchar(contract_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = TRUE)
  expect_equal(urps_count(2023L, FALSE), contract$abog_active)
  expect_equal(urps_count(2023L, TRUE), contract$combined_active)
  expect_equal(contract$combined_active, contract$abog_active + contract$abu_net_new)
})
