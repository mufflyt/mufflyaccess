# Architecture — the URPS / workforce SSOT

Three layers, one direction of data flow. Each owns exactly one thing, and no
layer reaches past the one below it.

```
isochrones
  Owns raw and cleaned provider-level rosters
  Owns certification, retirement, NPI matching, and deduplication
  Produces immutable, hashed workforce snapshots

              ↓ published artifact

mufflyaccess
  Owns definitions and stable analytical interfaces
  Owns the scenario dictionary (named scenarios + lever values), not the model
  Validates the supplied snapshot
  Returns counts, metadata, and provenance
  Contains no alternative provider-cleaning pipeline

              ↓ package dependency

cliff / twostep / manuscripts / apps
  Call mufflyaccess
  Never hardcode or independently derive national URPS counts
```

## isochrones — provider truth
The **only** place provider records are cleaned. It owns rosters, certification,
retirement, NPI matching, and deduplication, and emits an **immutable, hashed
workforce snapshot** as its published artifact.

## mufflyaccess — definitions + interface
Owns the **definitions** (what "active URPS", "with / without urology", the
active-in-year rule, and each cohort mean) and the **stable analytical
interface**. It **validates** the supplied snapshot (hash + schema) before using
it, **fails loud** on a mismatch, and **returns** counts, metadata, and
provenance. It contains **no alternative provider-cleaning pipeline** — it never
re-derives rosters, retirement, or dedup; it consumes isochrones' snapshot as
given.

## cliff / twostep / manuscripts / apps — consumers
Call `mufflyaccess` for every national URPS count. **Never** hardcode a count and
**never** independently derive one. Forward-projection scenarios are named from the
shared **scenario dictionary** ([`urps_scenarios()`]) — one vocabulary, not a
per-repo set — and a projection table's `scenario_id` column is validated against
it ([`validate_urps_scenarios()`]). mufflyaccess fixes what each scenario *is* (its
lever values: entrant multiplier, retirement-hazard shift, late-career FTE factor);
cliff owns what the levers *do* (the projection engine).

---

## Current conformance (status)

| Principle | Status | Where |
|---|---|---|
| Definitions live in `mufflyaccess` | ✅ | `R/urps_workforce.R` (cohorts, ± urology); `analysis/urps_counts/` (active-in-year rule, by-year interface) |
| Snapshot is validated by hash | ✅ | `analysis/urps_counts/freshness_check.py` checks the isochrones `table1` SHA-256 against the recorded fingerprint (`provenance.json`) |
| No provider cleaning here | ✅ | nothing in `mufflyaccess` re-derives certification / retirement / NPI match / dedup — those stay in isochrones |
| Counts come from validating + serving the snapshot | ✅ | `urps_count()` / `urps_counts()` read the shipped canonical table; `validate_urps_ssot()` fail-loud checks it against its manifest and asserts the deprecated `*_2025` constants still agree, so there is one enforced number |
| A single stable interface consumers call | ✅ | exported R API: `urps_count(year, include_urology)`, `urps_counts()`, `urps_provenance()`, `validate_urps_ssot()` |

### Bootstrap vs. canonical release
mufflyaccess ships a **bootstrap** artifact, not a canonical release, and says so
loudly: `urps_provenance()` reports `artifact_source = "bundled_bootstrap"`,
`canonical_release = FALSE`, and `suitable_for_release = FALSE`. Switching to a
real release is gated:

* `use_urps_artifact("<dir>")` **fails closed** — an invalid artifact errors and
  the active source is left unchanged.
* Selecting via the option/env var instead **warns + falls back** to the bootstrap
  and reveals it (`urps_provenance()$artifact_source` / `$external_artifact_error`);
  `options(mufflyaccess.urps_artifact_strict = TRUE)` promotes that to an error.
* `validate_urps_ssot(require_external = TRUE)` fails unless a real external
  release is active — the gate a release/integration job asserts.

The default is not switched from bootstrap to a release until the upstream
artifact is published, tagged, and passes these gates.

### Contract v3.0.0 (released)
**isochrones has published the versioned artifacts** at
`artifacts/workforce/` (artifact commit `cf7222df`, source `74085a9e6`): a
`measure × geography` `urps_counts_by_year.csv`, `urps_manifest.json`,
`urps_provider_snapshot.parquet`, and `urps_release_contract.json` — each hashed,
with its git SHA. mufflyaccess reads + validates that directory
(`validate_urps_artifact()`) and pins it in the `isochrones-integration` CI job;
the same bytes are bundled as the bootstrap so the default serves the canonical
numbers. The canonical 2023 estimand is **board_certified_active / national =
1306** (CONUS 1303; ABOG 1027 + ABU **279**), keyed on the URPS **subspecialty**
cert year. **1339 is the 2025 `roster_snapshot`** (distinct measure); **1332 /
1329 are RETIRED v2.1.0 cells** (primary-cert basis), surfaced only by
`urps_lineage()` / `urps_retired_values()`.

### Remaining (tracked in `handoff/STATUS.json`)
1. **cliff / twostep** consume the contract via
   `mufflyaccess::urps_count(2023, "board_certified_active", <geography>, ...)` with
   a guard that fails if an unqualified workforce total reappears. The 2023 active
   count is now **1306** (national) / **1303** (conus); 1332/1329 are retired and
   1339 is the 2025 roster snapshot. (cliff/twostep pin bumps to 0.7.0 happen when
   consumers are re-pinned to the release.)
2. The `handoff/isochrones/` producer copy can be archived now that the release is
   live; keep it only as a reference for regeneration.
