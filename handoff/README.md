# Handoff: apply the SSOT charter to isochrones, cliff, and twostep

These files are staged in `mufflyaccess` for review; **apply them in the named
repo**. They complete the isochrones -> mufflyaccess -> consumers dependency
direction (see `../ARCHITECTURE.md`). Status is tracked in `STATUS.json`.

## isochrones — RELEASED ✅
isochrones has published the **contract v3.0.0** artifacts under
`artifacts/workforce/` (artifact commit `cf7222df`, source `74085a9e6`):
`urps_counts_by_year.csv` (measure × geography), `urps_manifest.json`,
`urps_provider_snapshot.parquet`, `urps_release_contract.json`. mufflyaccess reads
+ validates them via `use_urps_artifact()` and pins the release in the
`isochrones-integration` CI job. The producer script
`isochrones/build_urps_workforce_artifacts.R` here is a **STALE v1.0.0** reference
(fused-geography schema, primary-cert/retired-1332 basis) — do **not** use it to
regenerate v3.0.0. Committing the real v3.0.0 producer in isochrones is the open
item (see `../docs/CHARTER_URPS_SSOT.md`).

## cliff
- `cliff/R/urps_baseline.R` — the only way cliff gets the baseline
  (`mufflyaccess::urps_count(year, measure, geography, include_urology)`); shows how
  to route `get_baseline("URPS")` through it. The 2023 active baseline is
  **1306** (national) / **1303** (conus) with urology (v3.0.0, URPS subspecialty-cert
  basis) — **not 1339** (that is the 2025 `roster_snapshot`), and **not 1332 / 1329**
  (those are RETIRED v2.1.0 primary-cert cells). Remove cliff's independent
  derivation and any hardcoded workforce total.
- `cliff/tests/testthat/test-no-unqualified-urps-baseline.R` — the shared guard
  (see below).
- Existing `test-mufflyaccess-contract.R` / `test-workforce-baseline.R` /
  `test-projection-starting-value.R` / `test-mufflyaccess-version.R` verify the
  baseline stays sourced from mufflyaccess and pinned.

## twostep
- `twostep/R/urps_workforce.R` — `urps_workforce_n(geography, ...)`; twostep is
  geography-aware, so the count MUST carry the same geography as its denominators
  and isochrone bands (`conus` → 1303, `national` → 1306 for 2023 active).
- `twostep/tests/testthat/test-no-unqualified-urps-baseline.R` — the shared guard.

## Shared guard — `_shared/test-no-unqualified-urps-baseline.R`
Copy verbatim into each consumer's `tests/testthat/`. It fails when a canonical
URPS **workforce total** (current 1306 / 1303, roster 1339 / 1336, or retired
1332 / 1329) appears as an **unqualified** baseline in production code (`R/`,
`manuscript/`, `scripts/`, `src/`, `inst/`). It
does **not** ban those values in tests, docs, vignettes, historical / comparison
tables, or NEWS, and it exempts any line that routes through
`mufflyaccess::urps_count(...)` or is annotated `# ssot-ok`. Anchors at the repo
root (nearest `DESCRIPTION`) so it works under `R CMD check`.

Handoff message to collaborators:

> Do not request or store a generic "URPS count." Always specify **year, measure,
> geography, pathway inclusion, and incomplete-data behavior**. The 2025 roster
> snapshot value of 1,339 must not be used as the 2023 active count (that is 1,306
> national / 1,303 CONUS under contract v3.0.0; 1,332 / 1,329 are retired cells).

Pin each consumer to a mufflyaccess commit (private repo -> needs `GITHUB_PAT`).
