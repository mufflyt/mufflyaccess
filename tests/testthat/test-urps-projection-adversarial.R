library(testthat)
library(mufflyaccess)

# ==============================================================================
# Semantic + adversarial coverage for the projection contract. "Semantic" = the
# contract's meaning holds (optional vs required, the FTE/flow/CI invariants, the
# baseline tie's pathway mapping); "adversarial" = a table that is valid except
# for ONE subtly-wrong cell must be rejected, and hostile inputs must fail loud.
# ==============================================================================

ex_path <- function() {
  system.file("extdata", "urps_projection_example.csv",
    package = "mufflyaccess"
  )
}
good <- function() read_urps_projection(ex_path(), validate = FALSE)

# a minimal, self-built valid table (only the required columns)
req_only <- function() {
  data.frame(
    year = c(2025L, 2026L, 2025L, 2026L),
    scenario_id = c("baseline", "baseline", "retire_2yr_earlier", "retire_2yr_earlier"),
    specialty = "URPS", certification_pathway = "ABOG_PLUS_ABU",
    geography_type = "national", geography_id = "US",
    supply_headcount = c(1306, 1290, 1306, 1279), stringsAsFactors = FALSE
  )
}

# ---- SEMANTIC: optional vs required, deterministic rows ----------------------

test_that("a required-columns-only table validates (optional columns may be absent)", {
  expect_true(validate_urps_projection(req_only()))
})

test_that("dropping a REQUIRED column fails; dropping an OPTIONAL one does not", {
  d <- good()
  expect_error(
    validate_urps_projection(d[setdiff(names(d), "geography_id")]),
    "missing required column"
  )
  # optional columns: CI, flow, and FTE can all go
  d2 <- d[setdiff(names(d), c(
    "lower_95", "upper_95", "entrants", "exits",
    "net_change", "supply_clinical_fte"
  ))]
  expect_true(validate_urps_projection(d2))
})

test_that("deterministic rows (NA 95% bounds) are allowed", {
  d <- req_only()
  d$lower_95 <- NA_real_
  d$upper_95 <- NA_real_
  expect_true(validate_urps_projection(d))
})

# ---- SEMANTIC: the baseline tie honours the pathway -> include_urology map ----

test_that("baseline_tie compares against the right urps_count() pathway", {
  # ABOG-only baseline stock must equal urps_count(2025, roster, national, FALSE) = 1031
  abog <- data.frame(
    year = 2025L, scenario_id = "baseline", specialty = "URPS",
    certification_pathway = "ABOG", geography_type = "national", geography_id = "US",
    supply_headcount = 1031, stringsAsFactors = FALSE
  )
  expect_true(validate_urps_projection(abog, baseline_tie = list(
    year = 2025, measure = "roster_snapshot",
    geography_type = "national", certification_pathway = "ABOG"
  )))
  # claiming ABOG but carrying the +urology stock (1339) must fail the tie
  abog$supply_headcount <- 1339
  expect_error(
    validate_urps_projection(abog, baseline_tie = list(
      year = 2025, measure = "roster_snapshot",
      geography_type = "national", certification_pathway = "ABOG"
    )),
    "does not match urps_count"
  )
})

test_that("baseline_tie catches a RETIRED starting stock smuggled in as supply", {
  d <- good()
  d$supply_headcount[d$scenario_id == "baseline" & d$year == 2025] <- 1332 # retired v2.1.0 cell
  expect_error(
    validate_urps_projection(d, baseline_tie = list(
      year = 2025, measure = "roster_snapshot",
      geography_type = "national", certification_pathway = "ABOG_PLUS_ABU"
    )),
    "does not match urps_count"
  )
})

test_that("baseline_tie fails loudly when no baseline row exists for the tie key", {
  # a valid urps_count() cell (2023 active = 1306) the example carries no row for
  # (the example projection starts at 2025) -> the tie finds zero baseline rows
  expect_error(
    validate_urps_projection(good(), baseline_tie = list(
      year = 2023, measure = "board_certified_active",
      geography_type = "national", certification_pathway = "ABOG_PLUS_ABU"
    )),
    "need exactly 1"
  )
})

# ---- SEMANTIC: the clinical-FTE bound ---------------------------------------

test_that("supply_clinical_fte must lie in [0, supply_headcount]", {
  d <- req_only()
  d$supply_clinical_fte <- d$supply_headcount * 0.85 # plausible
  expect_true(validate_urps_projection(d))
  d$supply_clinical_fte[1] <- d$supply_headcount[1] + 1 # more FTE than heads
  expect_error(validate_urps_projection(d), "cannot exceed supply_headcount")
  d$supply_clinical_fte <- -1 # negative FTE
  expect_error(validate_urps_projection(d), "non-negative")
})

# ---- SEMANTIC: the flow identity tolerance ----------------------------------

test_that("net_change identity respects the tolerance boundary", {
  d <- good()
  i <- which(!is.na(d$net_change))[1]
  d$net_change[i] <- d$net_change[i] + 1e-9 # below default tol
  expect_true(validate_urps_projection(d))
  d$net_change[i] <- d$net_change[i] + 1e-3 # above default tol
  expect_error(validate_urps_projection(d), "flow identity")
  # a caller can tighten the tolerance
  d2 <- good()
  j <- which(!is.na(d2$net_change))[1]
  d2$net_change[j] <- d2$net_change[j] + 1e-4
  expect_error(validate_urps_projection(d2, tol = 1e-6), "flow identity")
})

# ---- ADVERSARIAL: one-cell mutations of an otherwise-valid table ------------

test_that("single-cell mutations are each caught", {
  base_ok <- function() {
    expect_true(validate_urps_projection(good()))
    good()
  }

  d <- base_ok()
  d$scenario_id[2] <- "baseline " # trailing space
  expect_error(validate_urps_projection(d), "unregistered scenario_id")

  d <- base_ok()
  d$geography_type[1] <- "National" # wrong case (vocab is exact)
  expect_error(validate_urps_projection(d), "geography_type")

  d <- base_ok()
  d$certification_pathway[1] <- "ABOG+ABU" # not the enum spelling
  expect_error(validate_urps_projection(d), "certification_pathway")

  d <- base_ok()
  i <- which(!is.na(d$lower_95))[1]
  d$lower_95[i] <- d$supply_headcount[i] + 1 # CI no longer brackets
  expect_error(validate_urps_projection(d), "bounds do not bracket")

  d <- base_ok()
  d$entrants[which(!is.na(d$entrants))[1]] <- -5
  expect_error(validate_urps_projection(d), "non-negative")

  d <- base_ok()
  d <- rbind(d, d[2, ]) # duplicate series key
  expect_error(validate_urps_projection(d), "duplicate")

  d <- base_ok()
  d <- d[d$scenario_id != "baseline", ] # baseline dropped
  expect_error(validate_urps_projection(d), "baseline")
})

test_that("thousands-separated / non-numeric supply is not silently coerced", {
  d <- good()
  d$supply_headcount <- as.character(d$supply_headcount)
  d$supply_headcount[3] <- "1,307" # comma -> as.numeric NA
  expect_error(validate_urps_projection(d), "non-NA number")
})

# ---- ADVERSARIAL: the reader validates by default, and guards its path -------

test_that("read_urps_projection validates by default and rejects a bad file", {
  bad <- good()
  bad$scenario_id[1] <- "not_a_scenario"
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(bad, f, row.names = FALSE, na = "")
  expect_error(read_urps_projection(f), "unregistered scenario_id") # auto-validate
  expect_s3_class(read_urps_projection(f, validate = FALSE), "data.frame") # opt out
})

test_that("read_urps_projection guards its path argument", {
  expect_error(read_urps_projection(tempfile(fileext = ".csv")), "existing CSV") # missing
  expect_error(read_urps_projection(c("a", "b")), "path to an existing CSV") # non-scalar
  d <- tempfile()
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  expect_error(suppressWarnings(read_urps_projection(d))) # a directory
})
