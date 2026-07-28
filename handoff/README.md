# Handoff: apply the SSOT charter to isochrones and cliff

These files are staged in `mufflyaccess` for review; **apply them in the named
repo**. They complete the isochrones -> mufflyaccess -> consumers dependency
direction (see `../ARCHITECTURE.md`). `mufflyaccess` (this repo) is already done.

## 1 + 2 -> isochrones: `isochrones/build_urps_workforce_artifacts.R`
Copy to isochrones (e.g. `scripts/`), edit the `cfg` paths to the immutable
provider snapshot + ABU roster, and run. It emits, under
`artifacts/workforce/`: `urps_provider_snapshot.parquet`,
`urps_counts_by_year.csv`, `urps_manifest.json`. The ABOG counting is verified to
reproduce the SSOT (2023 = 1031). **Item 2** (by-year with-urology) happens
automatically when the ABU roster carries `certification_year`; otherwise ABU is
emitted as a 2023 snapshot. Then point mufflyaccess's readers at this released
artifact (replacing its bootstrap `inst/extdata/` table).

## 3 -> cliff
- `cliff/R/urps_baseline.R` -- the only way cliff gets the baseline
  (`mufflyaccess::urps_count()`); shows how to route `get_baseline("URPS")`
  through it. Remove cliff's independent derivation + any hardcoded
  1031/1339/1295/264/308, and label the reconciliation doc archival.
- `cliff/tests/testthat/test-urps-baseline-guard.R` -- fails if the baseline
  stops matching mufflyaccess, or if a hardcoded baseline literal reappears.

Pin cliff to a mufflyaccess commit (private repo -> needs `GITHUB_PAT`).
