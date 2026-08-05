library(testthat)

# ==============================================================================
# checkmate structural / type contracts for the public API return values.
# checkmate's expect_* assertions pin the SHAPE of each return -- frame vs list,
# column types, name sets, value domains, missingness -- declaratively, so a
# silent type/shape regression in an accessor fails loudly. Skips where checkmate
# is unavailable (it is a Suggests dependency).
# ==============================================================================

test_that("urps_scenarios() is a typed registry frame", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  d <- urps_scenarios()
  expect_data_frame(d, min.rows = 9, col.names = "unique")
  expect_names(names(d), must.include = c(
    "scenario_id", "family", "label", "entrant_multiplier",
    "retirement_shift_years", "late_career_fte_factor",
    "late_career_fte_onset_age", "requires_fte_model", "description"))
  expect_character(d$scenario_id, any.missing = FALSE, unique = TRUE, min.chars = 1L)
  expect_subset(d$family, c("reference", "retirement", "entry", "fte", "demand", "composite"))
  expect_numeric(d$entrant_multiplier, lower = 0, finite = TRUE, any.missing = FALSE,
                 len = nrow(d))
  expect_integerish(d$retirement_shift_years, any.missing = FALSE)
  expect_numeric(d$late_career_fte_factor, lower = 0, finite = TRUE, any.missing = FALSE)
  expect_integerish(d$late_career_fte_onset_age)               # NAs permitted here
  expect_logical(d$requires_fte_model, any.missing = FALSE, len = nrow(d))
})

test_that("urps_scenario() returns a fully typed named record", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  s <- urps_scenario("combined_investment")
  expect_list(s, names = "named")
  expect_names(names(s), must.include = c(
    "scenario_id", "family", "label", "entrant_multiplier", "retirement_shift_years",
    "late_career_fte_factor", "requires_fte_model", "components", "registry_version"))
  expect_string(s$label, min.chars = 1L)
  expect_string(s$registry_version, pattern = "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  expect_number(s$entrant_multiplier, lower = 0, finite = TRUE)
  expect_int(s$retirement_shift_years)
  expect_character(s$components, any.missing = FALSE, min.len = 2L)   # a composite
  expect_null(urps_scenario("baseline")$components)                  # a single lever
})

test_that("scenario ids, predicate, and registry version have stable types", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  ids <- urps_scenario_ids()
  expect_character(ids, any.missing = FALSE, unique = TRUE, min.len = 9L)
  expect_logical(is_urps_scenario(ids), any.missing = FALSE, len = length(ids))
  expect_string(URPS_SCENARIO_REGISTRY_VERSION, pattern = "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

test_that("urps_projection_schema() and contract version are well typed", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  sch <- urps_projection_schema()
  expect_data_frame(sch, min.rows = 13L, col.names = "unique")
  expect_names(names(sch), permutation.of = c("column", "type", "optional", "description"))
  expect_character(sch$column, any.missing = FALSE, unique = TRUE)
  expect_character(sch$type, any.missing = FALSE)
  expect_logical(sch$optional, any.missing = FALSE)
  expect_string(URPS_PROJECTION_CONTRACT_VERSION, pattern = "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

test_that("read_urps_projection() yields a typed long frame; validate returns a scalar flag", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  f <- system.file("extdata", "urps_projection_example.csv", package = "mufflyaccess")
  p <- read_urps_projection(f, validate = FALSE)
  expect_data_frame(p, min.rows = 1L, col.names = "unique")
  expect_names(names(p), must.include = c(
    "year", "scenario_id", "specialty", "certification_pathway",
    "geography_type", "geography_id", "supply_headcount"))
  expect_integer(p$year, any.missing = FALSE)
  expect_character(p$scenario_id, any.missing = FALSE)
  expect_numeric(p$supply_headcount, lower = 0, any.missing = FALSE)
  expect_logical(validate_urps_projection(p), len = 1L, any.missing = FALSE)
})

test_that("urps_count() returns a single non-negative integer", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  expect_int(urps_count(2023, "board_certified_active", "national", TRUE),  lower = 1L)
  expect_int(urps_count(2013, "board_certified_active", "national", FALSE), lower = 1L)
  expect_int(urps_count(2025, "roster_snapshot",        "conus",    TRUE),  lower = 1L)
})

test_that("urps_counts() wide slice is a typed frame with status enums", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  w <- urps_counts()
  expect_data_frame(w, min.rows = 11L, col.names = "unique")   # 2013-2023
  expect_integer(w$year, any.missing = FALSE, unique = TRUE)
  expect_integerish(w$abog_active)
  expect_class(w$snapshot_date, "Date")
  expect_subset(w$abog_active_status,     c("observed", "derived", "unavailable"))
  expect_subset(w$combined_active_status, c("observed", "derived", "unavailable"))
})

test_that("urps_provenance() carries well-formed provenance fields", {
  skip_if_not_installed("checkmate")
  library(checkmate)
  pv <- urps_provenance()
  expect_list(pv, names = "named")
  expect_names(names(pv), must.include = c(
    "artifact_version", "contract_version", "measure_years", "snapshot_date",
    "source_sha256", "source_git_commit", "package_version"))
  expect_string(pv$contract_version,  pattern = "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  expect_string(pv$source_sha256,     pattern = "^[0-9a-f]{64}$")
  expect_string(pv$source_git_commit, pattern = "^[0-9a-f]{40}$")
  expect_class(pv$snapshot_date, "Date")
  expect_integer(pv$measure_years, any.missing = FALSE, min.len = 1L)
})
