# Shared helpers for the isochrones <-> mufflyaccess producer/consumer tests.
# The checked-in fixture under fixtures/isochrones-v2.1.0/ holds the REAL
# immutable v2.1.0 release bytes (verified SHA-256 against the manifest). CI can
# override with a fresh isochrones checkout via MUFFLYACCESS_URPS_ARTIFACT_DIR.

urps_fixture_dir <- function(name = "isochrones-v2.1.0") {
  testthat::test_path("fixtures", name)
}

# Resolve the real release: an env-pinned checkout (CI) else the checked-in fixture.
real_isochrones_artifact_path <- function() {
  env <- Sys.getenv("MUFFLYACCESS_URPS_ARTIFACT_DIR", "")
  if (nzchar(env) && file.exists(file.path(env, "urps_counts_by_year.csv"))) return(env)
  urps_fixture_dir()
}

reset_urps_artifact <- function() use_urps_artifact(NULL)

# copy a fixture into a fresh tempdir so a test can mutate it safely
copy_urps_fixture <- function(name = "isochrones-v2.1.0") {
  src <- urps_fixture_dir(name)
  dst <- file.path(tempfile("urps_fx_"))
  dir.create(dst, recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files(src, full.names = TRUE), dst, overwrite = TRUE)
  dst
}
copy_real_isochrones_artifact <- function() {
  src <- real_isochrones_artifact_path()
  dst <- file.path(tempfile("urps_real_"))
  dir.create(dst, recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files(src, full.names = TRUE), dst, overwrite = TRUE)
  dst
}

read_isochrones_manifest <- function(path) {
  jsonlite::read_json(file.path(path, "urps_manifest.json"), simplifyVector = TRUE)
}
read_urps_counts_csv <- function(path) {
  utils::read.csv(file.path(path, "urps_counts_by_year.csv"),
                  stringsAsFactors = FALSE, na.strings = c("", "NA"))
}

# edit the manifest in place with a function(manifest) -> manifest
edit_manifest <- function(path, fn) {
  p <- file.path(path, "urps_manifest.json")
  m <- jsonlite::read_json(p, simplifyVector = TRUE)
  m <- fn(m)
  jsonlite::write_json(m, p, auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(path)
}
# edit the release contract in place
edit_contract <- function(path, fn) {
  p <- file.path(path, "urps_release_contract.json")
  ct <- jsonlite::read_json(p, simplifyVector = TRUE)
  ct <- fn(ct)
  jsonlite::write_json(ct, p, auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(path)
}
# edit the counts data.frame in place with function(df) -> df
mutate_counts <- function(path, fn) {
  p <- file.path(path, "urps_counts_by_year.csv")
  d <- utils::read.csv(p, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  d <- fn(d)
  utils::write.csv(d, p, row.names = FALSE, na = "")
  invisible(path)
}
# set a single (year,measure,geography,pathway) cell to a value
mutate_count_cell <- function(path, year, measure, geography, pathway, value) {
  mutate_counts(path, function(d) {
    i <- d$year == year & d$measure == measure & d$geography == geography &
         d$board_pathway == pathway
    d$n_active[i] <- value
    d
  })
}
# drop all rows for a measure x geography
remove_count_cells <- function(path, measure, geography) {
  mutate_counts(path, function(d)
    d[!(d$measure == measure & d$geography == geography), , drop = FALSE])
}

# recompute the CSV SHA-256 into the manifest so ONLY semantics (not the
# checksum) are what a validation failure can be attributed to.
refresh_fixture_hashes <- function(path) {
  testthat::skip_if_not_installed("digest")
  csv <- file.path(path, "urps_counts_by_year.csv")
  sha <- digest::digest(file = csv, algo = "sha256")
  edit_manifest(path, function(m) {
    if (!is.null(m$output_files) && !is.null(m$output_files$urps_counts_by_year_csv))
      m$output_files$urps_counts_by_year_csv$sha256 <- sha
    if (!is.null(m$artifact_sha256)) m$artifact_sha256 <- sha
    m
  })
}

# provider parquet reader (arrow or nanoparquet); skip the test when neither.
read_provider_parquet <- function(path) {
  pq <- file.path(path, "urps_provider_snapshot.parquet")
  testthat::skip_if(!file.exists(pq), "no provider parquet in artifact")
  if (requireNamespace("arrow", quietly = TRUE))
    return(as.data.frame(arrow::read_parquet(pq)))
  if (requireNamespace("nanoparquet", quietly = TRUE))
    return(as.data.frame(nanoparquet::read_parquet(pq)))
  testthat::skip("no parquet reader (arrow / nanoparquet) available")
}

# parquet mutations (need a reader AND writer; skip when unavailable)
have_arrow <- function() requireNamespace("arrow", quietly = TRUE)
mutate_future_provider_activity <- function(path, active) {
  testthat::skip_if_not(have_arrow(), "arrow required to mutate the provider parquet")
  pq <- file.path(path, "urps_provider_snapshot.parquet")
  d <- as.data.frame(arrow::read_parquet(pq))
  fut <- !is.na(d$certification_year) & d$certification_year >= 2024L
  if (isTRUE(active)) {
    d$certification_year[fut] <- 2023L
    if ("active_2023" %in% names(d)) d$active_2023[fut] <- TRUE
  }
  arrow::write_parquet(d, pq)
  invisible(path)
}
mark_unknown_provider_conus <- function(path) {
  testthat::skip_if_not(have_arrow(), "arrow required to mutate the provider parquet")
  pq <- file.path(path, "urps_provider_snapshot.parquet")
  d <- as.data.frame(arrow::read_parquet(pq))
  if ("is_conus" %in% names(d)) d$is_conus[!isTRUE(d$is_conus)][1] <- TRUE
  arrow::write_parquet(d, pq)
  invisible(path)
}
