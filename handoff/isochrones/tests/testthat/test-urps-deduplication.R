# tests/testthat/test-urps-deduplication.R   [APPLY IN: isochrones]
library(testthat)
test_that("ABOG providers are not counted again as ABU net-new", {
  skip_if_not_installed("arrow")
  path <- file.path("artifacts", "workforce", "urps_provider_snapshot.parquet")
  skip_if_not(file.exists(path))
  providers <- arrow::read_parquet(path)
  abog_npis <- unique(providers$npi[providers$board_pathway == "ABOG" & !is.na(providers$npi)])
  abu_net_new_npis <- unique(providers$npi[providers$board_pathway == "ABU_NET_NEW" & !is.na(providers$npi)])
  expect_length(intersect(abog_npis, abu_net_new_npis), 0,
    info = "ABU_NET_NEW must exclude providers already represented in the ABOG cohort")
})
