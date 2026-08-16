library(testthat)
library(mufflyaccess)

# Mutation matrix against the authentic release: copy, mutate one property,
# refresh the checksum (so a FAILURE is attributable to SEMANTICS, not the hash),
# and prove adoption fails closed. This shows validation is more than a checksum.

semantic_mutations <- list(
  list(
    name = "2023 national combined regressed to the retired 1332",
    mutate = function(p) {
      mutate_count_cell(
        p, 2023, "board_certified_active",
        "national", "ABOG_PLUS_ABU", 1332L
      )
    },
    error = "reconcil|semantic|provider"
  ),
  list(
    name = "2023 ABU net-new changed 279 -> 308",
    mutate = function(p) {
      mutate_count_cell(
        p, 2023, "board_certified_active",
        "national", "ABU_NET_NEW", 308L
      )
    },
    error = "reconcil|semantic|provider"
  ),
  list(
    name = "conus 2023 combined regressed to the retired 1329",
    mutate = function(p) {
      mutate_count_cell(
        p, 2023, "board_certified_active",
        "conus", "ABOG_PLUS_ABU", 1329L
      )
    },
    error = "reconcil|semantic|provider"
  ),
  list(
    name = "conus board_certified_active rows removed",
    mutate = function(p) remove_count_cells(p, "board_certified_active", "conus"),
    error = "incomplete.*geography|missing.*conus"
  ),
  list(
    name = "duplicate count key",
    mutate = function(p) {
      mutate_counts(p, function(d) {
        rbind(d, d[d$year == 2023 & d$measure == "board_certified_active" &
          d$geography == "national" & d$board_pathway == "ABOG", ])
      })
    },
    error = "duplicate"
  ),
  list(
    name = "missing pathway row",
    mutate = function(p) {
      mutate_counts(p, function(d) {
        d[!(d$year == 2023 & d$measure == "board_certified_active" &
          d$geography == "national" & d$board_pathway == "ABOG_PLUS_ABU"), , drop = FALSE]
      })
    },
    error = "pathway|incomplete"
  ),
  list(
    name = "2025 snapshot mislabeled as a 2024 board-certified year",
    mutate = function(p) {
      mutate_counts(p, function(d) {
        r <- d[d$year == 2023 & d$measure == "board_certified_active" &
          d$geography == "national", ]
        r$year <- 2024L
        rbind(d, r)
      })
    },
    error = "2013.*2023|window|unsupported"
  ),
  list(
    name = "altered snapshot date in the manifest",
    mutate = function(p) {
      edit_manifest(p, function(m) {
        m$snapshot_date <- "2020-01-01"
        m
      })
    },
    error = "snapshot"
  ),
  list(
    name = "release-contract canonical cell disagrees with counts",
    mutate = function(p) {
      edit_contract(p, function(ct) {
        ct$canonical$n_active <- 1300L
        ct
      })
    },
    error = "disagree|canonical"
  )
)

for (case in semantic_mutations) {
  test_that(paste("mutation rejected:", case$name), {
    path <- copy_real_isochrones_artifact()
    case$mutate(path)
    # refresh the checksum unless the mutation targeted a non-CSV file
    if (file.exists(file.path(path, "urps_counts_by_year.csv"))) refresh_fixture_hashes(path)
    expect_error(use_urps_artifact(path), regexp = case$error, ignore.case = TRUE)
    expect_identical(getOption("mufflyaccess.urps_artifact_dir"), NULL) # fail closed
  })
}

# Provider-level semantic mutations require an arrow read/write; they skip when
# arrow is absent but run in the clean-room CI job where it is installed.
test_that("future certifications made active in 2023 are rejected", {
  path <- copy_real_isochrones_artifact()
  mutate_future_provider_activity(path, TRUE) # skips if arrow unavailable
  refresh_fixture_hashes(path)
  expect_error(use_urps_artifact(path),
    regexp = "certification|active_2023|temporal|reconstruction",
    ignore.case = TRUE
  )
})

test_that("an unknown-geography provider marked CONUS is rejected", {
  path <- copy_real_isochrones_artifact()
  mark_unknown_provider_conus(path) # skips if arrow unavailable
  refresh_fixture_hashes(path)
  expect_error(use_urps_artifact(path),
    regexp = "conus|reconstruction|geography", ignore.case = TRUE
  )
})
