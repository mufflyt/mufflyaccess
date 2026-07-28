#!/usr/bin/env Rscript
# ==============================================================================
# build_urps_workforce_artifacts.R   [APPLY IN: isochrones]
#
# Produces the one deterministic, versioned URPS workforce artifact set that
# mufflyaccess reads + validates. isochrones owns provider truth; this script is
# the ONLY producer of the published counts. Do not expose projection constants.
#
# Emits (under artifacts/workforce/):
#   urps_provider_snapshot.parquet   provider-level snapshot (immutable)
#   urps_counts_by_year.csv          year,board_pathway,n_active,n_ever_certified,
#                                    n_retired,snapshot_date,source_sha256,method_version
#   urps_manifest.json               sources+hashes, defs, dedup rule, scope,
#                                    limitations, git SHA
#
# Active-in-year rule (SSOT definition): active in Y iff
#   certification_year <= Y AND (retirement_year is empty OR retirement_year > Y)
# ==============================================================================
suppressWarnings(suppressMessages({ library(jsonlite) }))
has_arrow  <- requireNamespace("arrow",  quietly = TRUE)
has_digest <- requireNamespace("digest", quietly = TRUE)
sha256 <- function(path) if (has_digest) digest::digest(file = path, algo = "sha256") else NA_character_

## ---- config (edit paths to the immutable provider snapshot) -----------------
cfg <- list(
  abog_snapshot   = "manuscript/tables/table1_physician_characteristics.csv",
  abu_roster      = "data/abu_urology/abu_all_urps_2026-07-22.csv",  # optional
  urps_label      = "Female Pelvic Medicine & Reconstructive Surgery",
  years           = 2013:2023,
  snapshot_date   = "2026-07-22",
  method_version  = "2026-07-22.v1",
  out_dir         = "artifacts/workforce"
)

## ---- the counting definition (pure, testable) -------------------------------
active_in_year <- function(cert, ret, y) !is.na(cert) & cert <= y & (is.na(ret) | ret > y)

count_by_year <- function(df, years, cert_col = "certification_year",
                          ret_col = "retirement_year") {
  cert <- suppressWarnings(as.integer(df[[cert_col]]))
  ret  <- if (ret_col %in% names(df)) suppressWarnings(as.integer(df[[ret_col]])) else rep(NA_integer_, nrow(df))
  do.call(rbind, lapply(years, function(y) data.frame(
    year = y,
    n_active         = sum(active_in_year(cert, ret, y)),
    n_ever_certified = sum(!is.na(cert) & cert <= y),
    n_retired        = sum(!is.na(ret)  & ret  <= y),
    stringsAsFactors = FALSE)))
}

build <- function(cfg) {
  stopifnot(file.exists(cfg$abog_snapshot))
  abog_all <- utils::read.csv(cfg$abog_snapshot, stringsAsFactors = FALSE, check.names = FALSE)
  subcol   <- if ("subspecialty_label" %in% names(abog_all)) "subspecialty_label" else "subspecialty"
  abog     <- abog_all[abog_all[[subcol]] == cfg$urps_label, , drop = FALSE]
  abog_sha <- sha256(cfg$abog_snapshot)

  rows <- cbind(count_by_year(abog, cfg$years), board_pathway = "abog",
                snapshot_date = cfg$snapshot_date, source_sha256 = abog_sha,
                method_version = cfg$method_version)

  abu_sha <- NA_character_
  if (file.exists(cfg$abu_roster)) {
    abu     <- utils::read.csv(cfg$abu_roster, stringsAsFactors = FALSE, check.names = FALSE)
    abu_sha <- sha256(cfg$abu_roster)
    if ("certification_year" %in% names(abu)) {          # true by-year ABU
      ac <- cbind(count_by_year(abu, cfg$years), board_pathway = "abu",
                  snapshot_date = cfg$snapshot_date, source_sha256 = abu_sha,
                  method_version = cfg$method_version)
    } else {                                             # 2023 net-new snapshot only
      ac <- data.frame(year = 2023L, n_active = nrow(abu), n_ever_certified = NA_integer_,
                       n_retired = NA_integer_, board_pathway = "abu",
                       snapshot_date = cfg$snapshot_date, source_sha256 = abu_sha,
                       method_version = cfg$method_version)
    }
    rows <- rbind(rows, ac)
    # combined = abog + abu per shared year
    shared <- intersect(rows$year[rows$board_pathway == "abog"], ac$year)
    comb <- do.call(rbind, lapply(shared, function(y) {
      a <- rows$n_active[rows$board_pathway == "abog" & rows$year == y]
      b <- ac$n_active[ac$year == y]
      data.frame(year = y, n_active = a + b, n_ever_certified = NA_integer_,
                 n_retired = NA_integer_, board_pathway = "abog_plus_abu",
                 snapshot_date = cfg$snapshot_date, source_sha256 = abog_sha,
                 method_version = cfg$method_version) }))
    rows <- rbind(rows, comb)
  } else {
    message("[build] ABU roster not found -- emitting ABOG-only; add abu_roster for the with-urology series.")
  }

  cols <- c("year","board_pathway","n_active","n_ever_certified","n_retired",
            "snapshot_date","source_sha256","method_version")
  rows <- rows[order(match(rows$board_pathway, c("abog","abu","abog_plus_abu")), rows$year), cols]

  dir.create(cfg$out_dir, showWarnings = FALSE, recursive = TRUE)
  csv_path <- file.path(cfg$out_dir, "urps_counts_by_year.csv")
  utils::write.csv(rows, csv_path, row.names = FALSE, na = "")

  pq_path <- file.path(cfg$out_dir, "urps_provider_snapshot.parquet")
  if (has_arrow) arrow::write_parquet(abog, pq_path) else
    message("[build] arrow not installed -- skipping parquet (install arrow in isochrones).")

  git_sha <- tryCatch(system2("git", c("rev-parse","HEAD"), stdout = TRUE), error = function(e) "unknown")
  manifest <- list(
    artifact = "urps_counts_by_year.csv",
    artifact_sha256 = sha256(csv_path),
    provider_snapshot = "urps_provider_snapshot.parquet",
    provider_snapshot_sha256 = if (has_arrow) sha256(pq_path) else NA_character_,
    method_version = cfg$method_version,
    years = list(measure_year_range = range(cfg$years), headline_measure_year = 2023L,
                 snapshot_date = cfg$snapshot_date, model_baseline_year = 2025L),
    source_files = list(
      list(path = cfg$abog_snapshot, role = "ABOG active-workforce snapshot", sha256 = abog_sha),
      list(path = cfg$abu_roster,    role = "ABU net-new roster",             sha256 = abu_sha)),
    active_in_year_definition =
      "active in Y iff certification_year <= Y AND (retirement_year empty OR retirement_year > Y); retirement = 7-source consensus",
    abog_abu_dedup_rule =
      "ABU is NET-NEW to ABOG: ABU NPIs already in the ABOG cohort are removed; combined = ABOG + ABU (no double count)",
    geographic_scope = "National (United States)",
    known_limitations = c(
      "ABU by-year requires certification_year in the ABU roster; otherwise ABU is a 2023 snapshot.",
      "2013-2015 predate the ~2016 retirement-detection window and are approximate."),
    provenance_git_sha = list(isochrones = git_sha[1]))
  writeLines(toJSON(manifest, auto_unbox = TRUE, pretty = TRUE, null = "null"),
             file.path(cfg$out_dir, "urps_manifest.json"))
  message(sprintf("[build] wrote %d rows -> %s", nrow(rows), cfg$out_dir))
  invisible(rows)
}

if (sys.nframe() == 0L) build(cfg)
