# mufflyaccess

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.4.0-informational.svg)](DESCRIPTION)
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
renv::install("mufflyt/mufflyaccess")
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
  - [URPS workforce — the published SSOT](#urps-workforce--the-published-ssot)
  - [URPS scenario dictionary](#urps-scenario-dictionary)
  - [URPS projection contract](#urps-projection-contract)
  - [URPS clinical FTE (supply side)](#urps-clinical-fte-supply-side)
  - [URPS demand + gap](#urps-demand--gap)
  - [URPS workforce flows](#urps-workforce-flows)
  - [URPS geographic distribution + parameter CI](#urps-geographic-distribution--parameter-ci)
  - [Workforce & obstetric statistics](#workforce--obstetric-statistics)
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

The package is `renv`-pinned and light (base R + `stats` + `datasets`, plus
`jsonlite` for reading the workforce manifest):

```r
# latest from the default branch:
renv::install("mufflyt/mufflyaccess")

# or with remotes / pak:
remotes::install_github("mufflyt/mufflyaccess")
pak::pak("mufflyt/mufflyaccess")

# for an analysis you need to reproduce, pin an exact commit SHA:
renv::install("mufflyt/mufflyaccess@<commit-sha>")
```

Pin a specific commit for an analysis you need to reproduce: a shared SSOT should
change only on a deliberate, reviewed bump, and a commit SHA (recorded in
`renv.lock`) is what makes that pin reproducible.

### Access — this is a private repository

Installing (and `renv::restore()` from a consumer's lockfile) needs a GitHub
token with read access to `mufflyt/mufflyaccess`. `renv`, `remotes`, and `pak`
all read `GITHUB_PAT` automatically:

```r
# one-time, on each dev machine:
usethis::create_github_token()   # opens GitHub with the right scopes (repo read)
gitcreds::gitcreds_set()         # stores it (writes GITHUB_PAT to ~/.Renviron, chmod 600)
Sys.getenv("GITHUB_PAT") != ""   # verify it is set
```

A fine-grained token scoped to just this repo (Contents: read) is enough; a
classic PAT needs the `repo` scope. Keep the token in `~/.Renviron` (never the
project), ensure `.Renviron` is git-ignored, and in CI inject `GITHUB_PAT` as a
secret env var rather than a file. See [`.Renviron.example`](.Renviron.example).

No token, no network, no GitHub: install from a **local checkout** instead —
`renv::install("../mufflyaccess")` or `devtools::install_local("../mufflyaccess")`
— handy when the consumer repos are cloned side by side.

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

All 106 exported objects, grouped by domain.

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

### URPS workforce — the published SSOT

The national active URPS (urogynecology and reconstructive pelvic surgery) count.
**Consumers (`cliff` / `twostep` / manuscripts / apps) obtain it only through
these functions — never hardcode or independently derive a national URPS count**
(see [`ARCHITECTURE.md`](ARCHITECTURE.md)).

The workforce artifact follows the isochrones **contract v3.0.0** `measure × geography`
schema. The canonical 2023 estimand is **board_certified_active / national = 1306**
(CONUS 1303; ABOG **1027** + ABU net-new **279**), keyed on the URPS subspecialty
cert year. **1339 is the 2025 `roster_snapshot`, not the 2023 active count**, and
**1332 / 1329 are RETIRED v2.1.0 cells** (primary-cert basis) exposed only via
`urps_lineage()` / `urps_retired_values()` — never as current.

| Function | Returns |
|---|---|
| `urps_count(year, measure = "board_certified_active", geography = "national", include_urology = FALSE, incomplete = "error", details = FALSE)` | A **bare integer** `n_active`. `measure` ∈ `board_certified_active` (2013–2023) / `roster_snapshot` (2025); `geography` ∈ `national` / `conus` (case-insensitive). 2023 national: 1027 / **1306** (± urology); conus: 1026 / 1303. `incomplete = "na"` yields `NA` (never a silent 0); `details = TRUE` returns a labelled record. |
| `urps_lineage()` / `urps_retired_values()` | The contract lineage (current 3.0.0 = 1306/1303 vs retired 2.1.0 = 1332/1329) / the retired values, so consumers never present a retired count as current. |
| `urps_counts(measure, geography)` / `urps_counts_long()` | A **wide** slice (default `board_certified_active` / `national`, years 2013–2023, with `*_status` columns) / the complete **long** table across all cells. |
| `urps_provenance()` | Manifest as a list: `artifact_source`, `canonical_release`, `suitable_for_release`, `contract_version`, `canonical_2023_estimand`, `measures`, `geographies`, `snapshot_date` (Date), `source_sha256` / `source_git_commit`, `git_commit_semantics`, `package_version`, … |
| `validate_urps_artifact(path)` | Fail-loud **semantic** validation of an artifact directory: contract version, schema, year windows, both-geography completeness, reconciliation, hashes, canonical-cell agreement, and (with a parquet reader) provider reconstruction. |
| `validate_urps_ssot(counts = NULL, require_external, require_canonical, require_contract_version, require_source_git_commit)` | The active-artifact / wide-table check plus release gates. |
| `use_urps_artifact(dir)` | Point the readers at a released isochrones `artifacts/workforce/` directory. **Fails closed** via `validate_urps_artifact()`. `NULL` = bundled bootstrap. |
| `compare_urps_artifacts(old, candidate)` | Release-to-release drift report. |

```r
urps_count(2023, "board_certified_active", "national", FALSE)  # 1027L
urps_count(2023, "board_certified_active", "national", TRUE)   # 1306L  (not 1339, not the retired 1332)
urps_count(2023, "board_certified_active", "conus",    TRUE)   # 1303L
urps_count(2025, "roster_snapshot",        "national", TRUE)   # 1339L  (2025 snapshot)
urps_provenance()$canonical_2023_estimand    # "board_certified_active / national = 1306"
urps_lineage()                               # 3.0.0 current (1306/1303) + 2.1.0 retired (1332/1329)

# serve the released isochrones artifact instead of the bundled bootstrap:
use_urps_artifact("path/to/isochrones/artifacts/workforce")    # validated; fails closed
validate_urps_ssot(require_external = TRUE, require_contract_version = "3.0.0")
```

The shipped artifact carries the **v3.0.0 numbers** but is labeled a **bootstrap, not
the canonical release** — `urps_provenance()$canonical_release` is `FALSE` until you
point at the external immutable release. Selecting an external source via the
`mufflyaccess.urps_artifact_dir` option / `MUFFLYACCESS_URPS_ARTIFACT_DIR` env var
warns and falls back to the bootstrap if unusable (revealed by
`urps_provenance()$external_artifact_error`); `options(mufflyaccess.urps_artifact_strict
= TRUE)` makes that an error. The `isochrones-integration` workflow re-runs the
`test-isochrones-*` suite against a fresh isochrones checkout pinned by SHA.

The old `URPS_COUNT_ABOG_ONLY_2025` / `URPS_COUNT_ABOG_PLUS_ABU_2025` constants
are **deprecated** — they now **warn on access** (still returning 1031 / 1339, the
2025 roster snapshot values);
call `urps_count()` instead. Per the architecture, `isochrones` owns provider
cleaning and the hashed snapshot; `mufflyaccess` validates it and serves the
number; the by-year derivation reference lives in
[`analysis/urps_counts/`](analysis/urps_counts/).

### URPS scenario dictionary

The single versioned vocabulary of named forward-projection scenarios (14 today).
`mufflyaccess` owns the **definitions** — each scenario's lever settings and the
enum a projection table keys on; the projection **model** stays in `cliff`.

| Function | Returns |
|---|---|
| `urps_scenarios()` | The registry `data.frame`: one row per scenario with its `family`, label, the supply levers (`entrant_multiplier`, `retirement_shift_years`, `late_career_fte_factor` / `_onset_age`), the demand levers, and `requires_fte_model` / `requires_demand_model`. |
| `urps_scenario(scenario_id)` | One scenario's labelled definition (plus `components` for composites, `registry_version`); fail-loud on an unknown id. |
| `urps_scenario_ids()` / `is_urps_scenario(x)` | The enum / a vectorised, non-erroring membership predicate. |
| `validate_urps_scenarios(x)` | Fail-loud guard that every id in a character vector or a `data.frame`'s `scenario_id` column is registered. |
| `URPS_SCENARIO_REGISTRY_VERSION` | Semantic version of the registry. |

### URPS projection contract

The second producer→SSOT contract, mirroring the count artifact: `cliff` runs the
workforce projection and emits a long table; `mufflyaccess` validates (and can
serve) it, never running the model.

| Function | Returns |
|---|---|
| `urps_projection_schema()` | The canonical long-table column spec (`column`, `type`, `optional`, `description`). |
| `validate_urps_projection(x, baseline_tie = NULL, tol = 1e-6)` | Fail-loud contract check: every `scenario_id` registered + `baseline` present, count-contract `certification_pathway` / `geography_type` vocab, unique series keys, non-negative counts, 95% bounds bracket the point estimate, `0 ≤ supply_clinical_fte ≤ supply_headcount`, and `net_change == entrants − exits`. `baseline_tie` ties the baseline-year stock back to `urps_count()`. |
| `read_urps_projection(path, validate = TRUE, ...)` | Typed read (integer year, double measures) then validate. |
| `URPS_PROJECTION_CONTRACT_VERSION` | Semantic version of the contract. |

### URPS clinical FTE (supply side)

Convert a certified headcount into clinical-FTE capacity by age, pathway, and sex.
Each weight is ≤ 1, so effective FTE never exceeds headcount.

| Function | Returns |
|---|---|
| `urps_fte_weight(age, pathway, late_from_age, late_factor)` / `urps_fte_weight_sex(...)` | Per-provider FTE weight = age-productivity × pathway clinical-time × late-career factor (with a sex-stratified hours variant). |
| `urps_effective_fte(counts, scale = 1, ...)` / `urps_effective_fte_sex(...)` | Aggregate clinical FTE of an `(age, pathway[, sex], n)` cohort. |
| `urps_fte_scale(reference_counts, target_headcount)` / `urps_fte_scale_sex(...)` | Normalization scale anchoring a reference cohort's FTE to a target headcount. |
| `urps_supply_fte_sex(cohort, ...)` | Full supply pipeline: certified headcount → `supply_clinical_fte` (sex-stratified). |
| `urps_fte_age_curve()` / `urps_fte_predicted_hours()` / `urps_fte_sex_hours_params()` | The age-productivity curve / predicted weekly patient-care hours / the OLS hours-model parameters. |
| `URPS_FTE_PATHWAY_CLINICAL_TIME` | Pathway clinical-time weights (ABOG 1.00, ABU 0.70). |

### URPS demand + gap

The demand-side counterpart to the FTE supply. **Pre-calibration skeleton:** the
`urps_demand_*` functions return `NA` until `urps_demand_params()` carries fitted
coefficients, so consumers wire them now and they light up on calibration.

| Function | Returns |
|---|---|
| `urps_demand_fte(population, visits_per_fte, scenario_id)` / `urps_demand_clinical_fte(...)` | Projected demand in clinical-FTE units for a patient population + scenario (`NA` until calibrated). |
| `urps_gap_fte(supply_clinical_fte, demand_clinical_fte)` | `gap_fte = demand − supply` (positive = shortage). |
| `urps_demand_params()` / `urps_demand_scalars()` | The regression-parameter skeleton (with `calibration_status`) / the specialty × setting scalar table. |
| `urps_demand_levers(scenario_id)` / `urps_demand_scalar(setting)` | A scenario's four demand levers / one setting-of-care calibration scalar. |
| `URPS_DEMAND_VERSION` / `URPS_DEMAND_SCALARS_VERSION` | Semantic versions (pre-calibration `0.1.0`). |

### URPS workforce flows

Stock-and-flow primitives: retirement, labour-force participation, and entry.

| Function | Returns |
|---|---|
| `urps_retirement_hazard(...)` / `urps_survival_curve()` / `urps_retirement_params()` | Annual retirement hazard `P(retire | active)` / the full survival curve / literature-calibrated parameters. |
| `urps_p_active(age, sex)` / `urps_p_still_active(age, sex, pathway)` | Probability actively practicing given age (and sex / pathway). |
| `urps_lfp_curve()` / `urps_lfp_params()` / `urps_apply_lfp(cohort)` | Labour-force-participation curve / parameters / application to a certified cohort. |
| `urps_entrants(year)` / `urps_entry_counts()` | Board-certified URPS entrants for a year / entry into the certified stock by year and pathway. |
| `urps_retirement_status()` / `urps_require_retirement_ascertained()` | Departure-ascertainment status of the served artifact / a fail-loud guard so "unknown retirement" is never read as "zero departures". |

### URPS geographic distribution + parameter CI

| Function | Returns |
|---|---|
| `urps_allocate_national(n, ...)` / `urps_state_alloc_weights()` / `urps_state_entrant_shares()` | Allocate a national provider count to CONUS states / the allocation weights / HWMM-style entrant shares. |
| `urps_state_female_pop()` | ACS 2016–2020 CONUS female population by state. |
| `urps_projection_ci(...)` / `urps_ci_param_draw(...)` | Parametric-bootstrap projection confidence intervals / one parameter draw. |

### Workforce & obstetric statistics

Dependency-light statistics shared with the workforce-cliff manuscript.

| Function | Returns |
|---|---|
| `calculate_proportion_ci(x, n)` / `calculate_two_prop_test(...)` | Wilson-score CI for a proportion / two-proportion z-test with an `n ≥ 30` guard. |
| `calculate_replacement_gap(...)` / `calculate_rural_metro_comparison(...)` / `calculate_state_vulnerability(...)` | Retirees-vs-graduates replacement gap / rural-vs-metro at-risk comparison / state vulnerability ranking. |
| `cesarean_rate_for_year(years)` / `completed_parity_for_cohort(cohorts)` / `cohort_vaginal_exposure(cohorts)` | Interpolated obstetric-exposure series: total-cesarean rate, mean completed parity, cohort vaginal-delivery exposure. |

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

The exported surface is guarded by ~36 test files under `tests/testthat/`,
grouped by domain:

| Domain | Representative test files |
|---|---|
| Constants & derived invariants | `test-constants.R`, `test-promoted-ssots.R`, `test-deprecated-urps-constants.R` |
| Accessibility & safe-math | `test-accessibility-stats.R`, `test-safe-divide.R`, `test-workforce-statistics.R` |
| URPS count contract | `test-urps-count.R`, `test-urps-counts-table.R`, `test-validate-urps-ssot.R`, `test-producer-release-contract.R`, `test-contract-lineage.R` |
| Scenario dictionary & projection contract | `test-urps-scenarios.R`, `test-urps-scenarios-adversarial.R`, `test-urps-projection.R`, `test-urps-projection-adversarial.R`, `test-urps-projection-ci.R` |
| Supply / demand / flows | `test-urps-fte.R`, `test-urps-fte-sex.R`, `test-urps-demand.R`, `test-urps-demand-scalars.R`, `test-urps-flows.R`, `test-urps-lfp.R`, `test-urps-retirement.R`, `test-urps-state-alloc.R` |
| Obstetric exposure | `test-obstetric-exposure.R` |
| Isochrones cross-repo contract | `test-isochrones-*.R`, `test-use-urps-artifact.R` |
| Boundary-value & type guards | `test-urps-bva.R`, `test-urps-checkmate.R`, `test-urps-readiness.R` |

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
