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
**never** independently derive one.

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

### Contract v2.1.0 (released)
**isochrones has published the versioned artifacts** at
`artifacts/workforce/` (commit `91104c77`, source `565755b2`): a
`measure × geography` `urps_counts_by_year.csv`, `urps_manifest.json`,
`urps_provider_snapshot.parquet`, and `urps_release_contract.json` — each hashed,
with its git SHA. mufflyaccess reads + validates that directory
(`validate_urps_artifact()`) and pins it in the `isochrones-integration` CI job;
the same bytes are bundled as the bootstrap so the default already serves the
corrected numbers. The canonical 2023 estimand is **board_certified_active /
national = 1332** (ABOG 1031 + ABU **301**); **1339 is the 2025 `roster_snapshot`**,
kept as a distinct measure.

### Remaining (tracked in `handoff/STATUS.json`)
1. **cliff / twostep** switch their baseline to
   `mufflyaccess::urps_count(2023, "board_certified_active", <geography>, ...)` and
   add a test that fails if a hardcoded 1031/1332/1329/1339/301/308 reappears. Note
   the correction: the 2023 active count is **1332** (national) / **1329** (conus),
   **not** 1339.
2. The `handoff/isochrones/` producer copy can be archived now that the release is
   live; keep it only as a reference for regeneration.
