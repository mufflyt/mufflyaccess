#!/usr/bin/env Rscript
# Build the ACS/Sheps data-contract package from the mufflyaccess SSOT (v3.0.0).
# EVERYTHING derived is regenerated here -- do not hand-edit the outputs.
#
# SELF-INVALIDATING GUARD: generation ABORTS unless the served artifact is
# contract 3.0.0 from source commit 74085a9e6, with national active 1306 / CONUS
# 1303, and no generated output presents the retired 1332/1329 as current.
suppressWarnings(suppressMessages(library(mufflyaccess)))

EXPECT <- list(contract = "3.0.0",
               source_commit = "74085a9e695eec5350275a29d8655512ad57422b",
               national = 1306L, conus = 1303L,
               retired = c(1332L, 1329L))

out     <- "share/acs_sheps/out"
fixture <- file.path("tests", "testthat", "fixtures", "isochrones-v3.0.0")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
suppressMessages(use_urps_artifact(normalizePath(fixture)))
prov <- urps_provenance()

## ---- guard 1: contract identity ---------------------------------------------
stopifnot(
  "artifact is not contract 3.0.0"        = identical(prov$contract_version, EXPECT$contract),
  "source commit is not 74085a9e6"        = identical(prov$source_git_commit, EXPECT$source_commit),
  "national active is not 1306"           = urps_count(2023, "board_certified_active", "national", TRUE) == EXPECT$national,
  "CONUS active is not 1303"              = urps_count(2023, "board_certified_active", "conus", TRUE) == EXPECT$conus,
  "retired values not recorded as retired"= setequal(urps_retired_values(), EXPECT$retired))

nat <- format(EXPECT$national, big.mark = ","); con <- format(EXPECT$conus, big.mark = ",")

## ---- 1. national longitudinal series ----------------------------------------
series <- urps_counts_long()
series$artifact_version   <- prov$artifact_version
series$contract_version   <- prov$contract_version
series$source_git_commit  <- prov$source_git_commit
series$package_version     <- prov$package_version
series$completeness_status <- ifelse(is.na(series$n_active), "unavailable", "observed")
utils::write.csv(series, file.path(out, "urps_national_series_v3.0.0.csv"),
                 row.names = FALSE, na = "")

## ---- 2. headline-cell matrix (generated) ------------------------------------
hl <- function(m, g, p, y) urps_count(y, m, g, p)
mat <- data.frame(
  measure   = c("board_certified_active","board_certified_active","roster_snapshot","roster_snapshot"),
  geography = c("national","conus","national","conus"),
  year      = c(2023L,2023L,2025L,2025L),
  abog        = c(hl("board_certified_active","national",FALSE,2023), hl("board_certified_active","conus",FALSE,2023),
                  hl("roster_snapshot","national",FALSE,2025),        hl("roster_snapshot","conus",FALSE,2025)),
  combined    = c(hl("board_certified_active","national",TRUE,2023),  hl("board_certified_active","conus",TRUE,2023),
                  hl("roster_snapshot","national",TRUE,2025),         hl("roster_snapshot","conus",TRUE,2025)),
  stringsAsFactors = FALSE)
mat$abu_net_new <- mat$combined - mat$abog
utils::write.csv(mat[, c("measure","geography","year","abog","abu_net_new","combined")],
                 file.path(out, "urps_headline_matrix_v3.0.0.csv"), row.names = FALSE)

## ---- 3. provenance report ---------------------------------------------------
pv <- c(
  "URPS workforce SSOT -- provenance (contract v3.0.0)",
  "===================================================",
  sprintf("package_version         : mufflyaccess %s", prov$package_version),
  sprintf("artifact_source         : %s", prov$artifact_source),
  sprintf("contract_version        : %s", prov$contract_version),
  sprintf("artifact_version        : %s", prov$artifact_version),
  sprintf("canonical_2023_estimand : %s", prov$canonical_2023_estimand),
  sprintf("measures                : %s", paste(prov$measures, collapse = ", ")),
  sprintf("geographies             : %s", paste(prov$geographies, collapse = ", ")),
  sprintf("measure_years           : %d-%d", min(prov$measure_years), max(prov$measure_years)),
  sprintf("snapshot_date           : %s", as.character(prov$snapshot_date)),
  sprintf("source_git_commit       : %s", prov$source_git_commit),
  sprintf("git_commit_semantics    : %s", prov$git_commit_semantics),
  sprintf("active-in-year rule     : %s", prov$active_in_year_definition),
  sprintf("deduplication rule      : %s", prov$deduplication_rule),
  sprintf("retired cells           : v2.1.0 national %s / CONUS %s (primary-cert basis; NOT current)",
          prov$retired_cells$v2_1_0_national, prov$retired_cells$v2_1_0_conus),
  "",
  "Source description (verbatim from isochrones):",
  strwrap(prov$source_description, width = 78, prefix = "  "))
writeLines(pv, file.path(out, "urps_provenance.txt"))

## ---- 4. validation report ---------------------------------------------------
chk <- function(label, expr)
  sprintf("[%s] %s", tryCatch({ expr; "PASS" }, error = function(e) paste0("FAIL: ", conditionMessage(e))), label)
reader_note <- if (requireNamespace("arrow", quietly = TRUE) || requireNamespace("nanoparquet", quietly = TRUE))
  "provider-snapshot reconstruction: PERFORMED" else
  "provider-snapshot reconstruction: NOT RUN here (no parquet reader; run in CI with arrow)"
vr <- c(
  "URPS workforce SSOT -- validation report (contract v3.0.0)",
  "==========================================================",
  chk("artifact directory + schema (validate_urps_artifact)", validate_urps_artifact(normalizePath(fixture))),
  chk("release gate: external + canonical + contract 3.0.0",
      validate_urps_ssot(require_external = TRUE, require_canonical = TRUE, require_contract_version = "3.0.0")),
  chk("release gate: source git commit pin",
      validate_urps_ssot(require_external = TRUE, require_source_git_commit = prov$source_git_commit)),
  chk("national active == 1306 / CONUS active == 1303",
      stopifnot(urps_count(2023,"board_certified_active","national",TRUE) == 1306L,
                urps_count(2023,"board_certified_active","conus",TRUE) == 1303L)),
  chk("retired 1332/1329 are exposed only as retired",
      stopifnot(setequal(urps_retired_values(), c(1332L,1329L)))),
  paste0("[INFO] ", reader_note))
writeLines(vr, file.path(out, "urps_validation_report.txt"))

## ---- 5. MEASURE_CONTRACT.md (generated) -------------------------------------
mc <- c(
  "# URPS workforce -- measurement contract (for ACS / Sheps)",
  "",
  "_Generated from the isochrones contract v3.0.0 artifact. Do not hand-edit._",
  "",
  sprintf("**Canonical 2023 board-certified active count: national %s / CONUS %s** (URPS", nat, con),
  "subspecialty-cert basis). 1,339 is the 2025 roster snapshot, not the 2023 active",
  "count. **1,332 / 1,329 are RETIRED v2.1.0 cells (primary-cert basis) and must",
  "never be presented as current.**",
  "",
  "## Canonical call",
  "```r",
  "mufflyaccess::urps_count(year = 2023, measure = \"board_certified_active\",",
  "                         geography = \"national\", include_urology = TRUE,",
  sprintf("                         incomplete = \"error\", details = TRUE)   # %s", nat),
  "```",
  "",
  "## Headline cells (contract v3.0.0)",
  "",
  "| measure / geography | ABOG | ABU net-new | combined |",
  "|---|---|---|---|",
  sprintf("| board_certified_active / national / 2023 | %d | %d | **%d** |",
          mat$abog[1], mat$abu_net_new[1], mat$combined[1]),
  sprintf("| board_certified_active / conus / 2023 | %d | %d | **%d** |",
          mat$abog[2], mat$abu_net_new[2], mat$combined[2]),
  sprintf("| roster_snapshot / national / 2025 | %d | %d | **%d** |",
          mat$abog[3], mat$abu_net_new[3], mat$combined[3]),
  sprintf("| roster_snapshot / conus / 2025 | %d | %d | **%d** |",
          mat$abog[4], mat$abu_net_new[4], mat$combined[4]),
  "",
  "## Contract lineage",
  "",
  "| Contract | National active | CONUS active | Status | Basis |",
  "|---|---|---|---|---|",
  {
    lin <- urps_lineage()
    apply(lin, 1, function(r) sprintf("| %s | %s | %s | %s | %s |",
          r[["contract_version"]], r[["national_active"]], r[["conus_active"]],
          r[["status"]], r[["basis"]]))
  },
  "",
  "**Why 3.0.0 changed:** v2.1.0 counted active on the *primary* board-cert year",
  "(national 1,332). v3.0.0 keys on the *URPS subspecialty* cert year (training-",
  "accurate, post-fellowship); 33 providers whose subspecialty cert postdates 2023",
  sprintf("are correctly excluded, giving %s. The 2025 roster snapshot (1,339) is unchanged.", nat),
  "",
  "## Source",
  "",
  strwrap(prov$source_description, width = 80),
  "",
  "mufflyaccess owns the workforce counts + provenance. Population denominators and",
  "spatial access measures are owned by twostep / isochrones (see the join spec).")
writeLines(mc, file.path(out, "MEASURE_CONTRACT_v3.0.0.md"))

## ---- 6. join specification (owned-vs-supplied) ------------------------------
js <- data.frame(
  join_field = c("total_population","female_population","access_30min","e2sfca_score"),
  owner      = c("twostep","twostep","isochrones","twostep"),
  join_key   = c("state","state","state","state"),
  required_year = c(2023L,2023L,2023L,2023L),
  unit       = c("persons","persons","share_reached","supply_per_pop"),
  stringsAsFactors = FALSE)
utils::write.csv(js, file.path(out, "urps_state_join_spec_v3.0.0.csv"), row.names = FALSE)

## ---- guard 2: no generated output presents a retired value as current -------
gen <- list.files(out, full.names = TRUE)
for (f in gen) {
  txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
  for (rv in EXPECT$retired) {
    # a retired value is allowed only next to the word "retired"
    hits <- grepl(sprintf("(?<![0-9])%d(?![0-9])", rv), strsplit(txt, "\n")[[1]], perl = TRUE)
    lines <- strsplit(txt, "\n")[[1]]
    bad <- hits & !grepl("retired|RETIRED|Retired|2.1.0|primary-cert|primary cert", lines)
    if (any(bad))
      stop(sprintf("[guard] %s presents retired value %d as current (line: %s)",
                   basename(f), rv, trimws(lines[which(bad)[1]])), call. = FALSE)
  }
}

use_urps_artifact(NULL)
cat("share/acs_sheps regenerated as v3.0.0; self-invalidating guard passed.\n")
