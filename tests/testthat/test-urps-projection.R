library(testthat)
library(mufflyaccess)

ex_path <- function() system.file("extdata", "urps_projection_example.csv",
                                  package = "mufflyaccess")
good <- function() read_urps_projection(ex_path(), validate = FALSE)

test_that("the schema is the canonical long-table spec", {
  s <- urps_projection_schema()
  expect_s3_class(s, "data.frame")
  expect_true(all(c("column", "type", "optional", "description") %in% names(s)))
  expect_true(all(c("year", "scenario_id", "certification_pathway", "geography_type",
                    "supply_headcount", "supply_clinical_fte", "entrants", "exits",
                    "net_change") %in% s$column))
  expect_match(URPS_PROJECTION_CONTRACT_VERSION, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  # supply_clinical_fte and the CI/flow columns are optional; identity keys are not
  expect_true(s$optional[s$column == "supply_clinical_fte"])
  expect_false(s$optional[s$column == "scenario_id"])
})

test_that("the bundled example conforms and ties to the served count", {
  expect_true(validate_urps_projection(ex_path()))
  expect_true(validate_urps_projection(good()))
  # the 2025 baseline stock equals urps_count(2025, roster_snapshot, national, +uro) = 1339
  expect_true(validate_urps_projection(good(), baseline_tie = list(
    year = 2025, measure = "roster_snapshot",
    geography_type = "national", certification_pathway = "ABOG_PLUS_ABU")))
  # read_urps_projection typing
  d <- read_urps_projection(ex_path())
  expect_type(d$year, "integer")
  expect_type(d$supply_headcount, "double")
  expect_true(all(is.na(d$supply_clinical_fte)))   # NA until the FTE model (Phase 3)
})

test_that("missing required columns fail loud", {
  d <- good(); d$supply_headcount <- NULL
  expect_error(validate_urps_projection(d), "missing required column")
})

test_that("an unregistered scenario_id is rejected", {
  d <- good(); d$scenario_id[d$scenario_id == "fellowship_plus_10pct"] <- "made_up_scenario"
  expect_error(validate_urps_projection(d), "unregistered scenario_id")
})

test_that("the baseline scenario must be present", {
  d <- good(); d <- d[d$scenario_id != "baseline", ]
  expect_error(validate_urps_projection(d), "baseline")
})

test_that("unknown pathway / geography vocab are rejected", {
  d <- good(); d$certification_pathway[1] <- "ABMS"
  expect_error(validate_urps_projection(d), "certification_pathway")
  d <- good(); d$geography_type[1] <- "county"
  expect_error(validate_urps_projection(d), "geography_type")
})

test_that("duplicate series keys are rejected", {
  d <- good(); d <- rbind(d, d[1, ])
  expect_error(validate_urps_projection(d), "duplicate")
})

test_that("95% bounds must bracket the point estimate", {
  d <- good(); i <- which(!is.na(d$lower_95))[1]
  d$lower_95[i] <- d$supply_headcount[i] + 5    # lower above point
  expect_error(validate_urps_projection(d), "bounds do not bracket")
})

test_that("the flow identity net_change == entrants - exits is enforced", {
  d <- good(); i <- which(!is.na(d$net_change))[1]
  d$net_change[i] <- d$net_change[i] + 3
  expect_error(validate_urps_projection(d), "flow identity")
})

test_that("negative supply / exits are rejected", {
  d <- good(); d$supply_headcount[2] <- -1
  expect_error(validate_urps_projection(d), "non-negative")
})

test_that("baseline_tie catches a starting stock that disagrees with the SSOT", {
  d <- good(); d$supply_headcount[d$scenario_id == "baseline" & d$year == 2025] <- 1306
  expect_error(validate_urps_projection(d, baseline_tie = list(
    year = 2025, measure = "roster_snapshot",
    geography_type = "national", certification_pathway = "ABOG_PLUS_ABU")),
    "does not match urps_count")
  # a bad pathway for the tie is rejected up front
  expect_error(validate_urps_projection(good(), baseline_tie = list(
    year = 2025, measure = "roster_snapshot",
    geography_type = "national", certification_pathway = "ABU_NET_NEW")),
    "ABOG or ABOG_PLUS_ABU")
})
