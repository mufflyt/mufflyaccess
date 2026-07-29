# ACS / Sheps data-contract package — URPS workforce

A compact, governed data package to share with the ACS / Sheps core unit — **not a
single headline number**. It establishes the measurement contract first, then
provides the validated series, a small geographic extract, and full provenance.

## Contents

| File | What it is |
|---|---|
| [`MEASURE_CONTRACT.md`](MEASURE_CONTRACT.md) | Measure crosswalk + data dictionary + the canonical `urps_count()` call. **Read first.** |
| `out/urps_national_series_v2.1.0.csv` | The validated national longitudinal series (measure × year × geography × pathway) with provenance columns. No physician-level data. |
| `out/urps_state_extract_2023_v2.1.0.csv` | State-level `board_certified_active` / 2023 **counts** (± urology). Denominators / access measures left as empty join columns (owned by twostep / isochrones). |
| `out/urps_provenance.txt` | Human-readable provenance (package/artifact/contract versions, snapshot date, source commit, definitions). |
| `out/urps_validation_report.txt` | Every governance check with pass/fail. |
| `build_share_package.R`, `build_state_extract.py` | Reproducible generators. |

Regenerate:

```sh
Rscript share/acs_sheps/build_share_package.R      # series + provenance + validation
python3 share/acs_sheps/build_state_extract.py     # state extract (needs pyarrow, or use arrow in R)
```

## The one distinction to lead with

**1,339 = the 2025 roster snapshot. The 2023 board-certified active count is 1,332
(national) / 1,329 (CONUS) — a different measure for a different year.** They are
intentionally non-interchangeable; requesting one measure's value for the other's
year is a hard error in the package.

## Suggested introductory email

> One important distinction in our data is that **roster snapshots and annual
> active-workforce estimates are separate measures**. For example, 1,339 is the
> count in our 2025 roster snapshot; it is **not** the 2023 board-certified active
> count (1,332 national / 1,329 contiguous-US), and the two are intentionally
> non-interchangeable.
>
> We expose the data through a versioned **measure × year × geography** contract.
> Each value carries provenance describing the measure, source artifact, snapshot
> date (where applicable), whether urology-pathway physicians are included,
> completeness, and the producing-source commit.
>
> As a starting point I can share: (1) a measure and data dictionary; (2) the
> validated national longitudinal series; (3) a small state- or county-level 2023
> extract; (4) the provenance and validation report; and (5) example access maps
> and summary figures.
>
> To make the first extract map cleanly to your structure: **is the ACS/Sheps core
> unit physician, facility, geography-year, or specialty-by-geography-year?** I'll
> shape the extract accordingly (a state-level 2023 extract is included here as a
> starting point).

## Boundaries

- mufflyaccess owns the **workforce counts and their provenance**. Population
  denominators, isochrone access bands, and maps are produced by **twostep /
  isochrones** and are referenced, not duplicated, here.
- Only **aggregate counts** are shared. No physician-level rows (NPI, name) leave
  this package.
- `git_commit_semantics` is reproduced verbatim from the isochrones manifest; the
  release does not expose a separate artifact-storage commit, so none is claimed.
