# mufflyaccess

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.8-informational.svg)](DESCRIPTION)
<!-- badges: end -->

**Single source of truth (SSOT) for the constants and pure statistics shared
across the OB/GYN subspecialty geographic-access projects — `isochrones`,
`twostep`, and `cliff`.**

Access research breaks quietly when three repositories each keep their own copy
of "the 60-minute band," "the total-female denominator," or "the ACS margin-of-
error multiplier," and the copies drift apart. `mufflyaccess` gives every
project **one** definition of each shared value, each carrying its provenance and
**fail-loud validation that runs at package load** — so the repositories cannot
silently disagree about the numbers behind a published statistic.

```r
renv::install("mufflyt/mufflyaccess@v0.1.8")
library(mufflyaccess)

# select the headline access rows in a Step-4 access table
filter(x, category == DENOMINATOR_CATEGORY, range == PRIMARY_ACCESS_BAND_SEC)
```

## Contents

- [Why this package exists](#why-this-package-exists)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Reference](#reference)
  - [Access bands & thresholds](#access-bands--thresholds)
  - [Census denominators](#census-denominators)
  - [Geography](#geography)
  - [Margins of error](#margins-of-error)
  - [Rurality (RUCA)](#rurality-ruca)
  - [Pelvic-floor-disorder prevalence](#pelvic-floor-disorder-prevalence)
  - [Accessibility-disparity statistics](#accessibility-disparity-statistics)
  - [Safe-division family](#safe-division-family)
- [Design principles](#design-principles)
- [What is intentionally *not* here](#what-is-intentionally-not-here)
- [Development](#development)
- [License](#license)

## Why this package exists

Three repositories analyze geographic access to OB/GYN subspecialists, and they
share a spine of numbers: which drive-time band is the headline result, what
population is the denominator, how a census tract counts as "covered," which
states are the contiguous US, how ACS margins of error convert to confidence
intervals, and so on. Each of those values is a decision with a citation behind
it. When a decision lives in three places it becomes three decisions.

`mufflyaccess` holds each such value **once**:

- **Provenance.** Every constant documents its source repo, table, vintage, or
  publication (e.g. Wu 2014, PMID 24463674).
- **Fail-loud validation.** Each `R/` file ends in a `stopifnot(...)` block that
  runs when the namespace loads. A value that is edited into an impossible state
  (a headline band outside the canonical set, a female population outside 150–175
  M, a RUCA cut outside 1–10) makes `library(mufflyaccess)` **error immediately**
  rather than shipping a wrong number downstream.
- **Derived, never duplicated.** Values that must agree are computed from one
  another — `PRIMARY_ACCESS_BAND_SEC` is `PRIMARY_ACCESS_BAND_MIN * 60`,
  `CONUS_STATE_ABBR` is derived from `CONUS_STATE_FIPS` through the canonical
  crosswalk — so the two forms can never drift.

## Installation

The package is `renv`-pinned and hermetic (base R + `stats` + `datasets` only —
no third-party runtime dependencies):

```r
# pin an exact release for reproducibility (recommended):
renv::install("mufflyt/mufflyaccess@v0.1.8")

# or with remotes / pak:
remotes::install_github("mufflyt/mufflyaccess@v0.1.8")
pak::pak("mufflyt/mufflyaccess@v0.1.8")
```

Pin a tagged version rather than tracking the branch: a shared SSOT should change
only on a deliberate, reviewed bump, and pinning is what makes an analysis
reproducible.

## Quick start

```r
library(mufflyaccess)

# 1. Select the headline access band in a Step-4 access table (range in seconds).
headline <- subset(access_tbl,
                   category == DENOMINATOR_CATEGORY &      # "total_female"
                   range    == PRIMARY_ACCESS_BAND_SEC)    # 3600

# 2. Restrict to the contiguous US.
conus <- subset(tracts, state_fips %in% CONUS_STATE_FIPS)  # 48 states + DC

# 3. Classify rurality from a USDA RUCA primary code.
tracts$rurality <- rurality_from_ruca(tracts$ruca)         # "Metropolitan"/"Rural"

# 4. Population-weighted mean access, with a Monte-Carlo 95% CI from ACS MOEs.
mc_weighted_ci(access = tracts$access,
               est    = tracts$female_pop,
               se     = tracts$female_moe / ACS_MOE_Z90,   # ACS MOE -> SE
               stat   = "mean")

# 5. Never divide by a zero denominator again.
safe_rate(events = subspecialists, exposure = female_pop, multiplier = 1e5)
```

## Reference

All 36 exported objects, grouped by domain.

### Access bands & thresholds

| Object | Type | Meaning |
|---|---|---|
| `PRIMARY_ACCESS_BAND_MIN` | int | Headline drive-time band, **60 min** ("within 60 minutes of a subspecialist"). |
| `PRIMARY_ACCESS_BAND_SEC` | int | Same band in **seconds** (3600); the `range` value selecting it in access tables. *Derived* as `_MIN * 60`. |
| `CANONICAL_BANDS` | int[] | Full isochrone generation set `{30, 60, 120, 180}` min. The headline band must be a member. |
| `DENOMINATOR_CATEGORY` | chr | `"total_female"` — the access-table `category` row that is the denominator of every access percentage. |
| `TRACT_REACHED_COVERAGE_PCT` | int | **50%** — a tract is "reached" when ≥ this share of its women fall inside the isochrone. |
| `get_primary_access_band(units)` | fn | Returns the primary band in `"min"` (default) or `"sec"`. |
| `get_canonical_bands()` | fn | Returns `CANONICAL_BANDS`. |

### Census denominators

| Object | Type | Meaning |
|---|---|---|
| `ACS2020_CONUS_FEMALE_POP` | int | **164,690,617** — national contiguous-US female population (ACS 2016–2020 5-yr, `B01001_026`). Carries `vintage`/`table`/`scope`/`units` provenance attributes. |
| `TOTAL_FEMALE_VAR` | chr | ACS total-female variable code `"B01001_026"`. |
| `RACE_FEMALE_VARS` | chr[] | Named race/ethnicity female variable codes (`white_nh`, `hispanic`, `black`, `aian`, `asian`, `nhpi`). Footgun-guarded: race tables use `_017`, not `_026`. |

### Geography

| Object | Type | Meaning |
|---|---|---|
| `CONUS_STATE_FIPS` | chr[] | 49 two-digit FIPS codes — 48 states + DC. |
| `CONUS_STATE_ABBR` | chr[] | The USPS-abbreviation form of the same set, **derived** from `CONUS_STATE_FIPS` so the two can never drift. |
| `NON_CONTIGUOUS_FIPS` | chr[] | The 7 excluded FIPS codes (AK, HI, PR, GU, VI, AS, MP). |
| `NON_CONTIGUOUS_CODES` | chr[] | The same 7 as USPS codes. |

> **Note:** `c(state.abb, "DC")` (all 50 + DC) is a *state-validation* vocabulary,
> **not** CONUS — it still contains AK/HI. Use `CONUS_STATE_ABBR` for contiguous-US
> analyses.

### Margins of error

ACS publishes margins of error at the **90%** confidence level.

| Object | Value | Meaning |
|---|---|---|
| `ACS_MOE_Z90` | 1.645 | Census-documented 90% multiplier (`MOE_90 = ACS_MOE_Z90 * SE`). Do **not** substitute `qnorm(0.95)`; the rounded value is the published convention. |
| `CI_Z95` | 1.96 | 95% multiplier. |
| `MOE90_TO_CI95_FACTOR` | ≈ 1.1915 | Convert a 90% MOE to a 95% CI half-width. *Derived* as `CI_Z95 / ACS_MOE_Z90`. |

### Rurality (RUCA)

| Object | Value | Meaning |
|---|---|---|
| `RUCA_NONMETRO_MIN` | 4L | First **non-metropolitan** USDA RUCA primary code. Metro = 1–3, Rural = 4–10. |
| `rurality_from_ruca(code)` | fn | Maps RUCA primary code(s) to `"Metropolitan"`/`"Rural"` (`NA` for invalid). |

### Pelvic-floor-disorder prevalence

The **65+ access demand denominator** (Wu 2014, Table 1, PMID 24463674).

| Object | Type | Meaning |
|---|---|---|
| `WU2014_PFD_PREVALENCE` | data.frame | Age-specific symptomatic PFD prevalence by condition (`any_PFD`, `UI`, `FI`, `POP`) × bracket (`p_65_79`, `p_80plus`). |
| `pfd_prevalence(condition)` | fn | Two-bracket prevalence for one condition (default `"any_PFD"`). |
| `pfd_prevalence_acs_bands(condition)` | fn | The same, expanded across the six ACS 65+ age-band columns. |

### Accessibility-disparity statistics

Pure, dependency-light statistics (base R + `stats`) shared by the `isochrones`
and `twostep` pipelines.

| Object | Meaning |
|---|---|
| `weighted_mean_all(a, w)` | Population-weighted mean; `NA` if weights sum to 0 (sparse-group safe). |
| `zero_access_share(access, w)` | Percent of weighted population with access **exactly** 0. |
| `mc_weighted_ci(access, est, se, stat, ...)` | Monte-Carlo CI for a weighted `"mean"`/`"zero"` statistic; redraws weights ~ Normal(est, se). |
| `annual_trend(year, value)` | OLS temporal trend of an annual series (slope + 95% t-interval + p). |
| `tract_vintage_of(year)` | Census-tract boundary vintage for a study year (2010 ≤ 2019, 2020 ≥ 2020). |
| `acs_year_of(year)` | ACS 5-year data year, clamped to the 2013–2022 window. |

### Safe-division family

Six functions with one guarantee: a zero or `NA` denominator never produces
`Inf`, `NaN`, or an uncaught error — it returns a caller-specified default.

| Object | Returns on zero denominator | Use for |
|---|---|---|
| `safe_divide(num, den, ...)` | `NA_real_` | The core primitive inside pipeline computations. |
| `safe_divide_manu(num, den, fallback)` | `fallback` | Manuscript-script alias with `num`/`den`/`fallback` names. |
| `safe_percent(part, total, ...)` | `0` (default) | Standard pipeline/figure percentages. |
| `safe_pct_manu(num, den, digits)` | `NA_real_` | Manuscript percentages where a missing denominator must **not** read as 0%. |
| `safe_rate(events, exposure, multiplier, ...)` | `NA_real_` | Epidemiological rates (e.g. subspecialists per 100K women). |
| `safe_ratio(num, den, ...)` | `NA_real_` | Unitless ratios (MOE-to-estimate, physician-to-population). |

### URPS workforce (frozen headline counts)

Frozen active-workforce headcounts for urogynecology and reconstructive pelvic
surgery (URPS), so downstream code gets the **same headline number every time**
instead of re-deriving it. Each carries provenance attributes and fail-loud
validation.

| Object | Value | Meaning |
|---|---|---|
| `URPS_COUNT_ABOG_ONLY_2025` | 1031 | Active URPS, ABOG (OB/GYN) pathway only — **without** urology. |
| `URPS_COUNT_ABOG_PLUS_ABU_2025` | 1295 | Both-pathway — **with** urology (`= 1031 + 264` ABU net-new). |

> These frozen constants are the headline counterpart to the reproducible
> by-year pipeline in [`analysis/urps_counts/`](analysis/urps_counts/); the two
> agree on the ABOG active figure (1031). See that folder for counts by year and
> subspecialty and the active-vs-ever-certified accessor.

## Design principles

1. **One definition, everywhere.** If a value is shared, it lives here and only
   here. Consumers reference it; they never re-declare it.
2. **Provenance travels with the value.** Every constant documents where it comes
   from, so a reviewer can trace any published number to its source.
3. **Fail loud, fail at load.** Validation runs in `stopifnot()` when the
   namespace loads — an impossible edit breaks `library()` immediately instead of
   corrupting a downstream result.
4. **Derive, don't duplicate.** Related representations are computed from a single
   base, so they cannot drift (`_SEC` from `_MIN`; `_ABBR` from `_FIPS`).
5. **Hermetic and pinned.** Base R + `stats` + `datasets` only, installed at a
   tagged version — reproducibility over convenience.

## What is intentionally *not* here

Genuinely repo-specific values stay per-repository **by design**. The clearest
example: the `cliff` workforce-cliff supply/demand line uses a full-age
**Nygaard-2008** population-projection curve — a *different cohort and source*
from the 65+ **Wu-2014** access denominator that this package provides. The two
are not interchangeable, so the Nygaard curve is deliberately kept in `cliff` and
is **not** promoted here. When in doubt, a value belongs in `mufflyaccess` only if
the projects must **agree** on it.

## Development

```r
# run the full test suite (testthat 3e)
devtools::test()

# check the package
devtools::check()
```

The exported surface is guarded by four test files under `tests/testthat/`:

| Test file | Covers |
|---|---|
| `test-constants.R` | Canonical scalar/vector values and derived-consistency invariants. |
| `test-promoted-ssots.R` | Constants promoted from `isochrones` (MOE, RUCA, Wu-2014 PFD). |
| `test-accessibility-stats.R` | The weighted-mean / zero-share / MC-CI / trend statistics. |
| `test-safe-divide.R` | The safe-division family's zero-denominator guarantees. |

`NAMESPACE` is generated by roxygen — run `devtools::document()` rather than
editing it by hand. When you promote a new constant, add its primary-source
provenance and a fail-loud `stopifnot()` block in the same commit, and record the
change in [`NEWS.md`](NEWS.md). See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the
full promotion checklist and the consumer shim pattern.

Which repo consumes which export — the SSOT contract map — is documented in
[`docs/CROSS_REPO_USAGE.md`](docs/CROSS_REPO_USAGE.md) and can be regenerated with
[`tools/usage_matrix.sh`](tools/usage_matrix.sh).

## License

MIT © 2026 Tyler Muffly. See [LICENSE](LICENSE).
