# The observed workforce-exit SERVING contract: fail-loud until a real observed
# departures/hazard artifact is configured, then serve the frozen provider-level
# facts (departures, annual exit counts, age x year hazards) that cliff calibrates
# its forward departure process from. The BUILDER (provider-month panel ->
# confirmed exits) is a producer in analysis/urps_exit_panel/; this pins only the
# base-R serving layer against the bundled synthetic example artifacts.

dep_ex <- system.file("extdata", "urps_observed_departures_example.csv",
                     package = "mufflyaccess")
haz_ex <- system.file("extdata", "urps_exit_hazard_by_age_year_example.csv",
                     package = "mufflyaccess")

# ---- fail-loud by default (unascertained retirement is never zero departures) --

test_that("urps_departures() fails loud when no observed artifact is configured", {
  old <- options(mufflyaccess.urps_departures_path = NULL); on.exit(options(old), add = TRUE)
  Sys.unsetenv("MUFFLYACCESS_URPS_DEPARTURES")
  # default fixture is not_ascertained -> the ascertainment guard stops
  expect_error(urps_departures(), "not_ascertained|no departures artifact")
})

test_that("urps_exit_hazard_by_age_year() fails loud when unconfigured", {
  old <- options(mufflyaccess.urps_exit_hazard_path = NULL); on.exit(options(old), add = TRUE)
  Sys.unsetenv("MUFFLYACCESS_URPS_EXIT_HAZARD")
  expect_error(urps_exit_hazard_by_age_year(), "not_ascertained|no exit-hazard artifact")
})

# ---- serving the frozen provider-level departures --------------------------------

test_that("a configured departures artifact activates urps_departures()", {
  skip_if(!nzchar(dep_ex) || !file.exists(dep_ex), "example artifact not bundled")
  old <- options(mufflyaccess.urps_departures_path = dep_ex); on.exit(options(old), add = TRUE)

  d <- urps_departures()
  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), 10L)
  expect_true(all(c("provider_id", "exit_month", "exit_year",
                    "exit_reason", "retirement_observed") %in% names(d)))
  expect_s3_class(d$exit_month, "Date")
  expect_true(is.integer(d$exit_year))
  expect_true(all(d$exit_reason %in% c("retired", "workforce_exit")))
  expect_true(is.logical(d$retirement_observed))
  # retirement is a subset of workforce exit: every "retired" row has evidence
  expect_true(all(d$retirement_observed[d$exit_reason == "retired"]))
})

test_that("year bounds filter urps_departures() inclusively", {
  skip_if(!nzchar(dep_ex) || !file.exists(dep_ex), "example artifact not bundled")
  old <- options(mufflyaccess.urps_departures_path = dep_ex); on.exit(options(old), add = TRUE)

  expect_equal(nrow(urps_departures(start_year = 2022)), 4L)   # 2022 + 2023
  expect_equal(nrow(urps_departures(end_year = 2019)), 2L)     # 2019 only
  d22 <- urps_departures(start_year = 2022, end_year = 2022)
  expect_equal(nrow(d22), 2L)
  expect_true(all(d22$exit_year == 2022L))
})

test_that("a misconfigured departures path fails loud (never silently empty)", {
  old <- options(mufflyaccess.urps_departures_path = "/no/such/departures.csv")
  on.exit(options(old), add = TRUE)
  expect_error(urps_departures(), "not found")
})

# ---- annual exit counts (the n_retired the series can finally carry) -------------

test_that("urps_exit_counts() aggregates to annual observed counts", {
  skip_if(!nzchar(dep_ex) || !file.exists(dep_ex), "example artifact not bundled")
  old <- options(mufflyaccess.urps_departures_path = dep_ex); on.exit(options(old), add = TRUE)

  ec <- urps_exit_counts()
  expect_true(all(c("year", "n_retired", "n_retired_with_evidence",
                    "retirement_status", "retirement_definition") %in% names(ec)))
  expect_equal(nrow(ec), 5L)                                   # 2019..2023
  expect_true(all(ec$n_retired == 2L))                        # 2 departures / year
  expect_true(all(ec$n_retired_with_evidence == 1L))          # 1 evidenced retirement / year
  # evidenced retirements are a subset of all workforce exits
  expect_true(all(ec$n_retired_with_evidence <= ec$n_retired))
  expect_true(all(ec$retirement_status == "observed"))
  expect_true(all(ec$retirement_definition == "observed_workforce_exit"))
})

# ---- age x year exit hazard (cliff's forward-process calibration target) ---------

test_that("urps_exit_hazard_by_age_year() serves the frozen hazard artifact", {
  skip_if(!nzchar(haz_ex) || !file.exists(haz_ex), "example artifact not bundled")
  old <- options(mufflyaccess.urps_exit_hazard_path = haz_ex); on.exit(options(old), add = TRUE)

  h <- urps_exit_hazard_by_age_year()
  expect_true(all(c("age", "year", "n_at_risk", "n_exits", "exit_hazard",
                    "hazard_source") %in% names(h)))
  expect_true(all(h$n_exits <= h$n_at_risk))
  expect_true(all(h$exit_hazard >= 0 & h$exit_hazard <= 1))
  # hazard rises monotonically with age within a year
  h21 <- h[h$year == 2021, ]
  h21 <- h21[order(h21$age), ]
  expect_true(all(diff(h21$exit_hazard) > 0))
})

test_that("a misconfigured hazard path fails loud", {
  old <- options(mufflyaccess.urps_exit_hazard_path = "/no/such/hazard.csv")
  on.exit(options(old), add = TRUE)
  expect_error(urps_exit_hazard_by_age_year(), "not found")
})

# ---- the provider-month evidence contract ----------------------------------------

test_that("validate_urps_exit_evidence() accepts a well-formed evidence table", {
  ev <- data.frame(
    provider_id = c("1000000001", "1000000001"),
    month       = as.Date(c("2023-01-01", "2023-02-01")),
    source      = c("nppes", "medicare"),
    practice_evidence = c(TRUE, FALSE))
  expect_invisible(validate_urps_exit_evidence(ev))
  expect_true(validate_urps_exit_evidence(ev))
})

test_that("validate_urps_exit_evidence() rejects structural violations", {
  ev <- data.frame(provider_id = "1000000001", month = as.Date("2023-01-01"),
                   source = "nppes", practice_evidence = TRUE)
  expect_error(validate_urps_exit_evidence(list(a = 1)), "must be a data.frame")
  expect_error(validate_urps_exit_evidence(ev[, setdiff(names(ev), "source")]),
               "missing column")
  bad_month <- ev; bad_month$month <- "not-a-date"
  expect_error(validate_urps_exit_evidence(bad_month), "month")
})
