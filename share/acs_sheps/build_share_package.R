#!/usr/bin/env Rscript
# Build the ACS/Sheps data-contract package from the mufflyaccess SSOT.
#   1. urps_national_series_v2.1.0.csv   -- the validated long series + provenance
#   2. urps_provenance.txt               -- human-readable provenance
#   3. urps_validation_report.txt        -- every governance check, pass/fail
# The state extract (build_state_extract.py) needs a parquet reader; it is a
# separate step so this script has no hard arrow dependency.
suppressWarnings(suppressMessages(library(mufflyaccess)))

out    <- "share/acs_sheps/out"
fixture <- file.path("tests", "testthat", "fixtures", "isochrones-v2.1.0")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# Serve the real released artifact (external), not the bootstrap.
suppressMessages(use_urps_artifact(normalizePath(fixture)))
prov <- urps_provenance()

## 1. national longitudinal series (all measures x geographies) + provenance ----
series <- urps_counts_long()
series$artifact_version   <- prov$artifact_version
series$contract_version   <- prov$contract_version
series$source_git_commit  <- prov$source_git_commit
series$package_version     <- prov$package_version
series$completeness_status <- ifelse(is.na(series$n_active), "unavailable", "observed")
utils::write.csv(series, file.path(out, "urps_national_series_v2.1.0.csv"),
                 row.names = FALSE, na = "")

## 2. human-readable provenance ------------------------------------------------
pv <- c(
  "URPS workforce SSOT -- provenance",
  "=================================",
  sprintf("package_version         : mufflyaccess %s", prov$package_version),
  sprintf("artifact_source         : %s", prov$artifact_source),
  sprintf("contract_version        : %s", prov$contract_version),
  sprintf("artifact_version        : %s", prov$artifact_version),
  sprintf("canonical_release       : %s", prov$canonical_release),
  sprintf("suitable_for_release    : %s", prov$suitable_for_release),
  sprintf("canonical_2023_estimand : %s", prov$canonical_2023_estimand),
  sprintf("measures                : %s", paste(prov$measures, collapse = ", ")),
  sprintf("geographies             : %s", paste(prov$geographies, collapse = ", ")),
  sprintf("measure_years           : %d-%d", min(prov$measure_years), max(prov$measure_years)),
  sprintf("snapshot_date           : %s", as.character(prov$snapshot_date)),
  sprintf("roster reflects certs   : through %s", prov$roster_reflects_certifications_through),
  sprintf("geographic_scope        : %s", prov$geographic_scope),
  sprintf("source_sha256           : %s", prov$source_sha256),
  sprintf("source_git_commit       : %s", prov$source_git_commit),
  sprintf("git_commit_semantics    : %s", prov$git_commit_semantics),
  sprintf("active-in-year rule     : %s", prov$active_in_year_definition),
  sprintf("deduplication rule      : %s", prov$deduplication_rule),
  "",
  "Note: git_commit_semantics is reproduced verbatim from the isochrones",
  "manifest; the release does not expose a separate artifact-storage commit,",
  "so none is asserted here."
)
writeLines(pv, file.path(out, "urps_provenance.txt"))

## 3. validation report --------------------------------------------------------
chk <- function(label, expr) {
  res <- tryCatch({ expr; "PASS" }, error = function(e) paste0("FAIL: ", conditionMessage(e)))
  sprintf("[%s] %s", res, label)
}
have_reader <- requireNamespace("arrow", quietly = TRUE) ||
               requireNamespace("nanoparquet", quietly = TRUE)
reader_note <- if (have_reader) {
  "provider-snapshot reconstruction: PERFORMED (parquet reader available)"
} else {
  "provider-snapshot reconstruction: NOT RUN here (no parquet reader; run in CI with arrow)"
}
vr <- c(
  "URPS workforce SSOT -- validation report",
  "========================================",
  chk("artifact directory + schema (validate_urps_artifact)", validate_urps_artifact(normalizePath(fixture))),
  chk("release gate: external + canonical + contract 2.1.0",
      validate_urps_ssot(require_external = TRUE, require_canonical = TRUE,
                         require_contract_version = "2.1.0")),
  chk("release gate: source git commit pin",
      validate_urps_ssot(require_external = TRUE,
                         require_source_git_commit = prov$source_git_commit)),
  chk("reconciliation ABOG_PLUS_ABU == ABOG + ABU_NET_NEW (wide slice)",
      validate_urps_ssot(urps_counts("board_certified_active", "national"))),
  paste0("[INFO] ", reader_note),
  "",
  "Governance checks enforced by validate_urps_artifact():",
  "  supported contract major; measure x geography schema; per-measure year",
  "  windows; both-geography completeness; reconciliation; duplicate-key;",
  "  missing-pathway; snapshot-date; release-contract canonical-cell agreement;",
  "  CSV SHA-256 vs manifest; provider reconstruction (with a parquet reader);",
  "  fail-closed loading."
)
writeLines(vr, file.path(out, "urps_validation_report.txt"))

use_urps_artifact(NULL)
cat("wrote national series, provenance, and validation report to", out, "\n")
