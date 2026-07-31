# ACS / Sheps data-contract package — URPS workforce (contract v3.0.0)

A compact, governed data package to share with the ACS / Sheps core unit — **not a
single headline number**. It establishes the measurement contract first, then
provides the validated series, a small geographic extract, and full provenance.

> ⚠️ **Do not send the earlier v2.1.0 package.** Its 2023 active values (1,332 /
> 1,329) were computed on the *primary* board-cert basis and are **RETIRED**.
> Contract v3.0.0 is canonical.

## Contents (all generated — do not hand-edit)

| File | What it is |
|---|---|
| `out/MEASURE_CONTRACT_v3.0.0.md` | Measure crosswalk, headline matrix, contract lineage, and the canonical `urps_count()` call. **Read first.** |
| `out/urps_national_series_v3.0.0.csv` | Validated national series (measure × year × geography × pathway) + provenance columns. No physician-level data. |
| `out/urps_headline_matrix_v3.0.0.csv` | The four headline cells, generated from the API. |
| `out/urps_state_extract_2023_v3.0.0.csv` | State-level `board_certified_active` / 2023 **counts** (± urology); sums to 1,306. Counts only. |
| `out/urps_state_join_spec_v3.0.0.csv` | The join spec: which fields twostep / isochrones supply (population, access), by key/year — instead of shipping empty columns. |
| `out/urps_provenance.txt` / `out/urps_validation_report.txt` | Human-readable provenance and every governance check. |
| `out/urps_provenance.json` | The same provenance as machine-readable JSON — the full `urps_provenance(detailed = TRUE)` chain (source-roster hashes, `combined_source_sha256`, producing commit, output hashes, cohort/cert-basis, live SHA-256 integrity check) — for pipelines that consume it programmatically. |
| `build_share_package.R`, `build_state_extract.py` | Reproducible generators (self-invalidating). |

Regenerate (aborts unless the served artifact is contract 3.0.0 @ 74085a9e6, national 1,306 / CONUS 1,303, with no retired value shown as current):

```sh
python3 share/acs_sheps/build_state_extract.py    # state extract (needs pyarrow, or arrow in R)
Rscript share/acs_sheps/build_share_package.R     # everything else
```

## The one distinction to lead with

**The 2023 board-certified active count is 1,306 (national) / 1,303 (CONUS).**
1,339 is the 2025 roster snapshot — a different measure for a different year.
**1,332 / 1,329 are RETIRED v2.1.0 cells** (primary-cert basis) and must never be
presented as current. The measures are non-interchangeable; requesting one
measure's value for the other's year is a hard error.

## Suggested introductory email

> One important distinction in our data is that **roster snapshots and annual
> active-workforce estimates are separate measures**. Our current (contract
> v3.0.0) 2023 board-certified active count is **1,306 national / 1,303
> contiguous-US**. 1,339 is the **2025 roster snapshot**, not the 2023 active
> count; and our earlier 1,332 / 1,303… figures (1,332 / 1,329) were computed on
> an older basis and are **retired**, not competing estimates.
>
> We expose the data through a versioned **measure × year × geography** contract.
> Each value carries provenance describing the measure, source artifact, snapshot
> date, whether urology-pathway physicians are included, and the producing-source
> commit.
>
> As a starting point I can share: (1) a measure and data dictionary; (2) the
> validated national longitudinal series; (3) a small state-level 2023 extract;
> (4) the provenance and validation report; and (5) example access maps.
>
> To make the first extract map cleanly to your structure: **is the ACS/Sheps core
> unit physician, facility, geography-year, or specialty-by-geography-year?**

## Source wording (use verbatim; do not paraphrase)

> Publicly accessible ABOG physician-certification information, integrated with
> other public physician-practice sources and independently reconciled for
> workforce research. ABOG did not supply, license, or endorse this derived
> dataset.

Do not label the dataset “ABOG data”, “an ABOG roster”, “ABMS data”, or “official
ABOG workforce counts”.

## Boundaries

- mufflyaccess owns the **workforce counts + provenance**. Population denominators,
  isochrone access bands, and maps are produced by **twostep / isochrones** (see
  the join spec), referenced not duplicated.
- Only **aggregate counts** are shared. No physician-level rows (NPI, name) leave
  this package.
- `git_commit_semantics` is reproduced verbatim from the isochrones manifest; the
  release exposes no separate artifact-storage commit, so none is claimed.
