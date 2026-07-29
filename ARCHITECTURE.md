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

### Remaining (upstream)
The mufflyaccess side of the contract is in place (exported API, shipped canonical
table + manifest, fail-loud validation, deprecated constants, **and a reader that
consumes a released isochrones artifact** via `use_urps_artifact(dir)` — proven
end-to-end against a real artifact generated from the isochrones snapshot). What
remains is upstream and in other repos (tracked in `handoff/STATUS.json`):
1. **isochrones** publishes the versioned artifacts
   (`artifacts/workforce/urps_provider_snapshot.parquet`, `urps_counts_by_year.csv`,
   `urps_manifest.json`) with its own hashes + git SHA (the producer +
   unified-manifest contract are staged in `handoff/isochrones/`). mufflyaccess
   already reads + validates such a directory; point it there with
   `use_urps_artifact()` and it replaces the bundled BOOTSTRAP.
2. A single both-pathway snapshot: ABU (+308) is presently a 2023-only layer from
   the cliff reconciliation, not a hashed isochrones artifact — fold it in so the
   with-urology series is by-year too.
3. **cliff / twostep** switch their baseline to `mufflyaccess::urps_count(2023L, ...)`
   and add a test that fails if a hardcoded 1031/1339/1295/264/308 reappears.
