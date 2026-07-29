# mufflyaccess 0.5.0

* **Release-readiness gates + honest bootstrap labeling.** The bundled artifact is
  now explicitly marked a non-canonical bootstrap: `urps_provenance()` exposes
  `artifact_source` (`"bundled_bootstrap"` / `"external"`), `canonical_release`,
  `suitable_for_release` (both `FALSE` for the bootstrap), `contract_version`, and
  `external_artifact_error`.
* **Fail-closed vs. revealed-fallback split.** `use_urps_artifact("<dir>")` (the
  explicit call) now fails closed -- an invalid artifact errors and the previously
  active source is left unchanged, never silently continuing. Selecting a source
  through the `mufflyaccess.urps_artifact_dir` option / `MUFFLYACCESS_URPS_ARTIFACT_DIR`
  env var instead warns and falls back to the bundled bootstrap, revealing the
  fallback via `urps_provenance()$artifact_source` / `$external_artifact_error`.
* **Strict mode.** `options(mufflyaccess.urps_artifact_strict = TRUE)` turns that
  silent fallback into an error; `validate_urps_ssot(require_external = TRUE)`
  fails unless a real external release is active (for release/integration gates).
* **Explicit missingness.** `urps_count(year, include_urology, incomplete =
  c("error", "na"))` never returns a silent `0` for an unavailable year/cohort;
  `urps_counts()` adds `abog_active_status` / `abu_net_new_status` /
  `combined_active_status` columns (`snapshot` / `derived` / `unavailable`).
* **Geography assertion.** `urps_count(..., geography = "CONUS")` errors on a
  mismatch with the served artifact's declared scope; mufflyaccess never
  re-projects counts onto a geography the artifact was not built for.
* **Hand-off tracker.** `handoff/STATUS.json` records the temporary status of the
  isochrones/cliff patches; the producer now stamps `contract_version`,
  `canonical_release`, and `suitable_for_release` into the manifest.

# mufflyaccess 0.4.0

* **Wired in released isochrones artifacts.** `use_urps_artifact(dir)` points the
  SSOT readers at an isochrones `artifacts/workforce/` directory -- validating it
  first and reverting on failure; `NULL` resets to the bundled bootstrap. Also
  honored via the `mufflyaccess.urps_artifact_dir` option /
  `MUFFLYACCESS_URPS_ARTIFACT_DIR` env var. Verified end-to-end: a real artifact
  generated from the isochrones snapshot is read through
  `urps_count()` / `urps_provenance()` / `validate_urps_ssot()`, with provenance
  reporting the isochrones git commit.
* Unified the manifest schema across the isochrones producer and mufflyaccess
  reader (`artifact_version`, `created_at`, `measure_years`, `snapshot_date`,
  `boards`, `geographic_scope`, `active_in_year_definition`, `deduplication_rule`,
  `source_files` [path+sha256], `git_commit`, `method_version`, `artifact_sha256`,
  `output_files`).
* Hardened the reader to reject a malformed artifact (wrong `board_pathway`
  casing) with a clear error instead of a cryptic failure.

# mufflyaccess 0.3.0

* Reshaped the URPS SSOT interface to the cross-repo contract (the red-first
  contract tests are now green, verified against the installed package):
    - `urps_count(year, include_urology)` returns a **bare integer** with strict
      validation (rejects vector / NA / non-numeric `year`, non-logical / NA
      `include_urology`, and unavailable years).
    - `urps_counts()` returns the **wide** table: `year, abog_active, abu_net_new,
      combined_active, measure_year, snapshot_date` (Date), `method_version,
      source_sha256`.
    - `urps_provenance()` returns `measure_years`, `snapshot_date` (Date),
      `boards`, `geographic_scope`, definitions, `source_sha256` /
      `source_git_commit`, `method_version`, `package_version` -- measure year,
      snapshot date, and model baseline year kept separate.
    - `validate_urps_ssot(counts = NULL)` validates a supplied wide table (schema,
      unique + complete 2013:2023 years, 64-hex hashes, the reconciliation
      identity `combined = abog + abu`) or the bundled table.
* Canonical artifact is now LONG with UPPERCASE pathways (`ABOG` / `ABU_NET_NEW`
  / `ABOG_PLUS_ABU`) matching the isochrones producer contract. Added
  `inst/extdata/urps_release_contract.json` (identical copy shipped in isochrones).
* `URPS_COUNT_ABOG_ONLY_2025` / `URPS_COUNT_ABOG_PLUS_ABU_2025` are now
  **deprecated active bindings that warn on access** (still return 1031 / 1339).
* Added the mufflyaccess contract tests; `handoff/` gains the isochrones producer
  tests + release contract and the cliff consumer / guard / version tests.

# mufflyaccess 0.2.0

* **Published URPS workforce SSOT interface** (implements the isochrones ->
  mufflyaccess -> consumers charter in `ARCHITECTURE.md`). Ships a compact
  canonical table (`inst/extdata/urps_counts_by_year.csv`) + manifest
  (`inst/extdata/urps_manifest.json`) and a stable R API:
    - `urps_count(year = 2023L, include_urology = FALSE)` -- the accessor
      consumers call (2023 without urology = 1031, with urology = 1339);
    - `urps_counts()` -- the full year x pathway table;
    - `urps_provenance()` -- source files, hashes, definitions, scope, limits;
    - `validate_urps_ssot()` -- fail-loud check of table vs manifest + contract.
  Every count carries `measure_year` (2023), `snapshot_date` (2026-07-22), and
  `model_baseline_year` (2025) as SEPARATE attributes -- never one ambiguous year.
* **Deprecated** `URPS_COUNT_ABOG_ONLY_2025` / `URPS_COUNT_ABOG_PLUS_ABU_2025`
  (ambiguous `_2025` suffix); retained only as the cross-check
  `validate_urps_ssot()` asserts. Call `urps_count()` instead.
* `jsonlite` added to Imports (reads the workforce manifest).
* NOTE: the canonical table is a BOOTSTRAP of what isochrones will publish as
  `artifacts/workforce/{urps_provider_snapshot.parquet, urps_counts_by_year.csv,
  urps_manifest.json}`; the readers swap to that versioned release when it lands.
  ABU is a 2023 snapshot only (no by-year series yet).

# mufflyaccess 0.1.10

* Added `urps_count()` -- the stable SSOT interface consumers call for the
  national URPS workforce count (`"abog_plus_abu"` = 1339 with urology,
  `"abog"` = 1031 without). Returns the count with metadata + provenance and
  optionally validates a supplied isochrones snapshot by SHA-256 (`digest`,
  Suggests). Formalizes the `ARCHITECTURE.md` contract: cliff / twostep /
  manuscripts / apps call `urps_count()` instead of reading the raw constant
  or hardcoding a number. Contains no provider cleaning -- it returns the
  reconciled value and the fingerprint of the snapshot it came from.

# mufflyaccess 0.1.9

* **Corrected the frozen with-urology URPS baseline** to the reconciled
  value: `URPS_COUNT_ABOG_PLUS_ABU_2025` is now **1339** (= 1031 ABOG + 308
  ABU net-new), superseding the stale 1295 (= 1031 + 264, pre-reinstatement),
  per cliff's `SSOT_URPS_BASELINE_RECONCILIATION.md` (2026-07-24). Fail-loud
  validation (264->308), provenance attributes, roxygen examples, README, and
  the analysis-doc pointer all updated to match. NOTE: this fixes the constant
  in THIS package only; the manuscript's own baseline SSOT (cliff
  `workforce_projections_consolidated.csv` + its frozen sensitivity suite)
  still needs the scoped re-run described in that doc.

# mufflyaccess 0.1.8

* Maintenance release: formally tags the consolidated 0.1.7 documentation,
  primary-source citations, cross-repo usage map, roxygen (package help page
  + examples/family/seealso), and the `analysis/urps_counts/` pipeline. No
  functional change to exported constants or functions since 0.1.7.
* Documented private-repo installation: consumers need a `GITHUB_PAT` (read
  access to `mufflyt/mufflyaccess`) for `renv::install()` / `renv::restore()`;
  added an install/auth section to the README, a `.Renviron.example` template,
  and a `.gitignore` that keeps a real `.Renviron` out of the repo. Generated
  `man/*.Rd` via roxygen2.

# mufflyaccess 0.1.7

* Extended the roxygen pass (docs-only; no code changed): fixed the malformed
  multi-`@param`-on-one-line blocks in `accessibility_stats.R` that 0.1.6 left in
  place (`w`/`est`/`se`/`stat`/`probs`/`seed`/`value` were undocumented), and
  added `@examples`/`@family`/`@seealso` to the remaining constant and accessor
  files 0.1.6 did not cover (access bands, geography, MOE, RUCA, census
  denominators, thresholds, categories) so the whole reference index is
  navigable. Run `devtools::document()` to regenerate `man/`.
* Documented the frozen URPS workforce constants (`URPS_COUNT_ABOG_ONLY_2025`,
  `URPS_COUNT_ABOG_PLUS_ABU_2025`, added in 0.1.5) in the README, alongside the
  by-year `analysis/urps_counts/` pipeline they reconcile with (both land on the
  1,031 ABOG active figure).
* Added a **package-level help page** (`?mufflyaccess`) via a `"_PACKAGE"` doc
  with a domain-grouped index of every export.
* Added `@examples`/`@family`/`@seealso` to the frozen URPS workforce constants
  (`R/urps_workforce.R`), and folded `WU2014_PFD_PREVALENCE` into the
  `pfd-prevalence` `@family` so the table and its accessors share one index page.

* Expanded `README.md` to a full reference of all 34 exported objects, grouped by
  domain, with design principles and a scope-boundary note.
* Added `URL` and `BugReports` to `DESCRIPTION`.
* Added this `NEWS.md` changelog.
* Strengthened `@source` provenance with **primary sources** (authoritative
  original references with URLs / DOIs) alongside the internal promotion paths:
  ACS Table B01001 for the female-population denominator and variable codes;
  U.S. Census Bureau ANSI/FIPS code lists for the state geography; USDA ERS
  Rural-Urban Commuting Area codes for the RUCA breakpoint; the Wu 2014 DOI and
  NHANES 2005-2010 data source for the PFD prevalence table; and the Census ACS
  data handbook for the margin-of-error multipliers.
* Added a **cross-repo usage map** (`docs/CROSS_REPO_USAGE.md`) — the SSOT
  contract map of which repo consumes which export — plus a regenerator,
  `tools/usage_matrix.sh`. Documents the origin (`isochrones`) vs consumer
  (`twostep`, `cliff`) shim architecture and flags exports no consumer references
  yet (the MOE multipliers, `CONUS_STATE_ABBR`, and the Wu-2014 PFD family).
* Switched `NAMESPACE` to **roxygen-generated** (removing the hand-maintenance
  drift risk) and declared the base-package dependencies in `DESCRIPTION`
  (`Imports: datasets, stats`; `Depends: R (>= 3.6)`).
* Added `CONTRIBUTING.md` codifying the promotion checklist (primary source +
  fail-loud `stopifnot()` + derive-don't-duplicate + test + `NEWS.md` + usage
  map) and the consumer shim pattern.
* Added `analysis/urps_counts/` (build-ignored, not part of the R package): a
  standard, reproducible count of URPS and all ABOG OB/GYN subspecialties by year
  (2013–2023), derived from the committed `isochrones` cohort
  (`table1_physician_characteristics.csv`) via the repo's board-certification
  active-in-year rule — never NPPES taxonomy alone. Includes the dependency-free
  generator (`count_urps.py`), the derived CSVs (by subspecialty; by ± urology
  pathway), provenance with source SHA-256, and heavy documentation. Anchors
  exactly to the known figures (URPS active 2023 = 1,031 ABOG; total = 5,336).
  The ABU (with-urology) layer is supported via `--abu`.
* Added `analysis/urps_counts/subspecialist_counts.R` — a base-R, fail-loud
  accessor over the committed CSV returning **active vs ever-certified** counts
  per subspecialty × year (plus `n_retired`, `pct_active`), with scalar helpers
  `n_active()` / `n_ever_certified()` and a CLI. Never hardcodes an integer;
  a returned number always traces to the committed source.
* Added `analysis/urps_counts/freshness_check.py` — SHA-256 freshness gate:
  compares the current isochrones `table1` hash against the one recorded in
  `provenance.json` (FRESH / STALE), with `--regenerate` to rebuild the CSVs
  when the source moved. Checks the derived counts, not the upstream pipeline.

# mufflyaccess 0.1.6

* Added `@examples`/`@family`/`@seealso` roxygen across the pure-function files
  (`accessibility_stats.R`, `pfd_prevalence.R`, `safe_divide.R`).

# mufflyaccess 0.1.5

* Froze the 2025 active URPS (urogynecology and reconstructive pelvic surgery)
  workforce headcounts as exported constants so downstream code gets the same
  number every time: `URPS_COUNT_ABOG_ONLY_2025` (1031 — ABOG/OB-GYN pathway,
  without urology) and `URPS_COUNT_ABOG_PLUS_ABU_2025` (1295 = 1031 + 264 ABU
  net-new, with urology), each with provenance attributes and fail-loud
  validation (`R/urps_workforce.R`).

# mufflyaccess 0.1.4

* Promoted the accessibility-disparity **pure statistics** shared by `isochrones`
  and `twostep` into `R/accessibility_stats.R`: `weighted_mean_all()`,
  `zero_access_share()`, `mc_weighted_ci()`, `annual_trend()`,
  `rurality_from_ruca()`, `tract_vintage_of()`, `acs_year_of()`, plus the ACS
  variable codes `TOTAL_FEMALE_VAR` and `RACE_FEMALE_VARS`. Base R + `stats` only.
* Promoted the **safe-division family** into `R/safe_divide.R`: `safe_divide()`,
  `safe_divide_manu()`, `safe_percent()`, `safe_pct_manu()`, `safe_rate()`, and
  `safe_ratio()` — one zero-denominator guarantee across all pipelines.

# mufflyaccess 0.1.3

* Promoted from `isochrones`: `RUCA_NONMETRO_MIN` (2-level metro/rural
  breakpoint), the ACS margin-of-error z multipliers (`ACS_MOE_Z90`, `CI_Z95`,
  `MOE90_TO_CI95_FACTOR`), and the Wu-2014 age-specific PFD prevalence table
  (`WU2014_PFD_PREVALENCE`, `pfd_prevalence()`, `pfd_prevalence_acs_bands()`).

# mufflyaccess 0.1.2

* Fixed the package test to strip provenance attributes before comparison
  (`expect_equal` attribute mismatch on `ACS2020_CONUS_FEMALE_POP`).

# mufflyaccess 0.1.1

* Attached `vintage`/`table`/`scope`/`units` provenance attributes to
  `ACS2020_CONUS_FEMALE_POP` to match consumer contracts.

# mufflyaccess 0.1.0

* Initial release: single-source-of-truth constants shared across the OB/GYN
  subspecialty geographic-access repositories (`isochrones`, `twostep`, `cliff`)
  — primary access band, canonical bands, total-female denominator category,
  tract "reached" coverage cut, national CONUS ACS female population, and the
  contiguous / non-contiguous state code lists. Every value carries provenance
  and fail-loud load-time validation.
