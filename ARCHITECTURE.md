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
| Counts come from validating + counting the snapshot | ⚠️ **gap** | the headline numbers are **frozen literals** (`URPS_COUNT_ABOG_PLUS_ABU_2025 = 1339L`), hand-set rather than *returned* by reading the validated snapshot — so the same number is derived in two places (the literal **and** the pipeline), the exact drift risk this model removes |
| A single stable interface consumers call | ⚠️ **gap** | the counting interface is Python in `analysis/` (build-ignored), not an exported R function; consumers can't yet `mufflyaccess::urps_count(...)` |

### Target to close the gaps
1. An exported R interface — e.g. `urps_count(snapshot, definition = c("abog", "abog_plus_abu"))` — that **validates** the isochrones snapshot's hash, **counts** from it, and **returns** `list(count, metadata, provenance)`.
2. The frozen `URPS_COUNT_*` constants become the *last-validated cached* value that interface returns (or are dropped), so there is exactly one derivation.
3. isochrones publishes its snapshot with a hash/manifest that `mufflyaccess` validates against (today `mufflyaccess` records the hash itself; ideally isochrones ships it).
