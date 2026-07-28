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

### Remaining (upstream)
The mufflyaccess side of the contract is in place (exported API, shipped canonical
table + manifest, fail-loud validation, deprecated constants). What remains is
upstream and in other repos:
1. **isochrones** publishes the versioned artifacts
   (`artifacts/workforce/urps_provider_snapshot.parquet`, `urps_counts_by_year.csv`,
   `urps_manifest.json`) with its own hashes + git SHA; mufflyaccess then reads that
   release instead of the current BOOTSTRAP table, and validates the parquet by hash.
2. A single both-pathway snapshot: ABU (+308) is presently a 2023-only layer from
   the cliff reconciliation, not a hashed isochrones artifact — fold it in so the
   with-urology series is by-year too.
3. **cliff / twostep** switch their baseline to `mufflyaccess::urps_count(2023L, ...)`
   and add a test that fails if a hardcoded 1031/1339/1295/264/308 reappears.
