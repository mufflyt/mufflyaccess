# Handoff: apply the SSOT charter to isochrones, cliff, and twostep

These files are staged in `mufflyaccess` for review; **apply them in the named
repo**. They complete the isochrones -> mufflyaccess -> consumers dependency
direction (see `../ARCHITECTURE.md`). Status is tracked in `STATUS.json`.

## isochrones — RELEASED ✅
isochrones has published the **contract v2.1.0** artifacts under
`artifacts/workforce/` (artifact commit `91104c77`, source `565755b2`):
`urps_counts_by_year.csv` (measure × geography), `urps_manifest.json`,
`urps_provider_snapshot.parquet`, `urps_release_contract.json`. mufflyaccess reads
+ validates them via `use_urps_artifact()` and pins the release in the
`isochrones-integration` CI job. The producer script
`isochrones/build_urps_workforce_artifacts.R` remains here as a regeneration
reference and can be archived.

## cliff
- `cliff/R/urps_baseline.R` — the only way cliff gets the baseline
  (`mufflyaccess::urps_count(year, measure, geography, include_urology)`); shows how
  to route `get_baseline("URPS")` through it. **Correction:** the 2023 active
  baseline is **1332** (national) / **1329** (conus) with urology — **not 1339**
  (that is the 2025 `roster_snapshot`). Remove cliff's independent derivation and
  any hardcoded workforce total.
- `cliff/tests/testthat/test-no-unqualified-urps-baseline.R` — the shared guard
  (see below).
- Existing `test-mufflyaccess-contract.R` / `test-workforce-baseline.R` /
  `test-projection-starting-value.R` / `test-mufflyaccess-version.R` verify the
  baseline stays sourced from mufflyaccess and pinned.

## twostep
- `twostep/R/urps_workforce.R` — `urps_workforce_n(geography, ...)`; twostep is
  geography-aware, so the count MUST carry the same geography as its denominators
  and isochrone bands (`conus` → 1329, `national` → 1332 for 2023 active).
- `twostep/tests/testthat/test-no-unqualified-urps-baseline.R` — the shared guard.

## Shared guard — `_shared/test-no-unqualified-urps-baseline.R`
Copy verbatim into each consumer's `tests/testthat/`. It fails when a canonical
URPS **workforce total** (1332 / 1329 / 1339 / 1336) appears as an **unqualified**
baseline in production code (`R/`, `manuscript/`, `scripts/`, `src/`, `inst/`). It
does **not** ban those values in tests, docs, vignettes, historical / comparison
tables, or NEWS, and it exempts any line that routes through
`mufflyaccess::urps_count(...)` or is annotated `# ssot-ok`. Anchors at the repo
root (nearest `DESCRIPTION`) so it works under `R CMD check`.

Handoff message to collaborators:

> Do not request or store a generic "URPS count." Always specify **year, measure,
> geography, pathway inclusion, and incomplete-data behavior**. The 2025 roster
> snapshot value of 1,339 must not be used as the 2023 active count (that is 1,332
> national / 1,329 CONUS).

Pin each consumer to a mufflyaccess commit (private repo -> needs `GITHUB_PAT`).
