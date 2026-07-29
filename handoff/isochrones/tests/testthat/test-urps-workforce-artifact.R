# tests/testthat/test-urps-workforce-artifact.R   [APPLY IN: isochrones]
library(testthat)
artifact_dir  <- file.path("artifacts", "workforce")
counts_path   <- file.path(artifact_dir, "urps_counts_by_year.csv")
provider_path <- file.path(artifact_dir, "urps_provider_snapshot.parquet")
manifest_path <- file.path(artifact_dir, "urps_manifest.json")
required_count_columns <- c("year","board_pathway","n_active","n_ever_certified",
  "n_retired","snapshot_date","source_sha256","method_version")
required_provider_columns <- c("provider_id","npi","board_pathway","certification_year",
  "retirement_year","active_2023","latitude","longitude")
read_counts   <- function() read.csv(counts_path, stringsAsFactors = FALSE, check.names = FALSE)
read_manifest <- function() jsonlite::read_json(manifest_path, simplifyVector = TRUE)

test_that("canonical workforce artifacts exist", {
  expect_true(file.exists(counts_path),   info = paste("Missing:", counts_path))
  expect_true(file.exists(provider_path), info = paste("Missing:", provider_path))
  expect_true(file.exists(manifest_path), info = paste("Missing:", manifest_path))
})
test_that("count artifact has the required schema", {
  skip_if_not(file.exists(counts_path)); counts <- read_counts()
  expect_setequal(required_count_columns, intersect(required_count_columns, names(counts)))
  expect_false(as.logical(anyDuplicated(counts[c("year","board_pathway")])))
  expect_true(all(!is.na(counts$year))); expect_true(all(!is.na(counts$board_pathway)))
  expect_true(all(!is.na(counts$n_active))); expect_true(all(counts$n_active >= 0))
  expect_true(all(counts$n_retired >= 0, na.rm = TRUE))
  expect_true(all(counts$n_ever_certified >= counts$n_active, na.rm = TRUE))
})
test_that("the canonical series covers 2013 through 2023", {
  skip_if_not(file.exists(counts_path))
  expect_setequal(unique(read_counts()$year), 2013:2023)
})
test_that("board pathways use controlled values", {
  skip_if_not(file.exists(counts_path)); counts <- read_counts()
  expect_true(all(counts$board_pathway %in% c("ABOG","ABU_NET_NEW","ABOG_PLUS_ABU")))
})
test_that("2023 headline counts are internally consistent", {
  skip_if_not(file.exists(counts_path)); c23 <- subset(read_counts(), year == 2023)
  abog <- c23$n_active[c23$board_pathway == "ABOG"]
  abu  <- c23$n_active[c23$board_pathway == "ABU_NET_NEW"]
  comb <- c23$n_active[c23$board_pathway == "ABOG_PLUS_ABU"]
  expect_equal(abog, 1031L); expect_equal(abu, 308L); expect_equal(comb, 1339L)
  expect_equal(comb, abog + abu)
})
test_that("provider snapshot has one row per canonical provider", {
  skip_if_not_installed("arrow"); skip_if_not(file.exists(provider_path))
  p <- arrow::read_parquet(provider_path)
  expect_true(all(required_provider_columns %in% names(p)))
  expect_false(as.logical(anyDuplicated(p$provider_id)))
  v <- p$npi[!is.na(p$npi) & nzchar(p$npi)]; expect_false(as.logical(anyDuplicated(v)))
})
test_that("2023 provider rows reconcile with the count table", {
  skip_if_not_installed("arrow"); skip_if_not(file.exists(provider_path)); skip_if_not(file.exists(counts_path))
  p <- arrow::read_parquet(provider_path); counts <- read_counts()
  expect_type(p$active_2023, "logical"); a <- p[p$active_2023, ]
  expect_equal(sum(a$board_pathway=="ABOG"), subset(counts, year==2023 & board_pathway=="ABOG")$n_active)
  expect_equal(sum(a$board_pathway=="ABU_NET_NEW"), subset(counts, year==2023 & board_pathway=="ABU_NET_NEW")$n_active)
})
test_that("active-in-year logic is temporally valid", {
  skip_if_not_installed("arrow"); skip_if_not(file.exists(provider_path))
  a <- (arrow::read_parquet(provider_path)); a <- a[a$active_2023, ]
  expect_true(all(a$certification_year <= 2023))
  expect_true(all(is.na(a$retirement_year) | a$retirement_year > 2023))
})
test_that("manifest contains complete provenance", {
  skip_if_not(file.exists(manifest_path)); m <- read_manifest()
  req <- c("artifact_version","created_at","measure_years","snapshot_date","geographic_scope",
           "active_in_year_definition","deduplication_rule","source_files","git_commit","method_version")
  expect_true(all(req %in% names(m)))
  expect_setequal(as.integer(m$measure_years), 2013:2023)
  expect_match(m$git_commit, "^[0-9a-f]{40}$")
  expect_identical(m$geographic_scope, "contiguous United States")
})
test_that("manifest records hashes for every source file", {
  skip_if_not(file.exists(manifest_path)); s <- read_manifest()$source_files
  expect_true(length(s) >= 1)
  hashes <- vapply(seq_len(nrow(s)), function(i) s$sha256[i], character(1))
  expect_true(all(grepl("^[0-9a-f]{64}$", hashes)))
})
test_that("canonical outputs are deterministic", {
  skip_if_not(file.exists(counts_path)); skip_if_not(file.exists(manifest_path))
  m <- read_manifest()
  expect_true("output_files" %in% names(m))
  expect_identical(digest::digest(file = counts_path, algo = "sha256"),
                   m$output_files$urps_counts_by_year_csv$sha256)
})
