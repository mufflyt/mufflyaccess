# mufflyaccess

Single source of truth for constants shared across the OB/GYN subspecialty
geographic-access repositories (**isochrones**, **twostep**, **cliff**):

| Object | Meaning |
|---|---|
| `PRIMARY_ACCESS_BAND_MIN` / `_SEC` | primary drive-time band (60 min / 3600 s) |
| `CANONICAL_BANDS` | full generation set {30,60,120,180} min |
| `DENOMINATOR_CATEGORY` | `"total_female"` access denominator label |
| `TRACT_REACHED_COVERAGE_PCT` | 50% majority "reached" cut |
| `ACS2020_CONUS_FEMALE_POP` | 164,690,617 national CONUS ACS female pop |
| `CONUS_STATE_FIPS` / `CONUS_STATE_ABBR` | 48 states + DC (abbr derived from FIPS) |
| `NON_CONTIGUOUS_FIPS` / `_CODES` | excluded AK/HI/territories |

Every value has fail-loud validation at load. Intentionally-different,
repo-specific values (e.g. Wu-2014 vs Nygaard-2008 PFD prevalence) are **not**
here and stay per-repository by design.

## Use

```r
# renv-pinned, hermetic:
renv::install("mufflyt/mufflyaccess@v0.1.0")
library(mufflyaccess)
filter(x, category == DENOMINATOR_CATEGORY, range == PRIMARY_ACCESS_BAND_SEC)
```
