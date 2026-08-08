# Cross-repo usage of the `mufflyaccess` SSOT

Which repository consumes which export. This is the **contract map** for the
single source of truth: it tells you, before you touch a constant, which repo's
results move when it changes — and which exports nothing consumes yet.

Regenerate the raw presence data at any time with
[`tools/usage_matrix.sh`](../tools/usage_matrix.sh) (see [below](#regenerating));
the interpretation in this file is layered on top of that raw grep.

## How the three repos relate

The projects adopt the SSOT through a **shim** pattern, so a shared value lives
in exactly one place:

- **`isochrones` — the origin.** The constants and pure statistics were *promoted
  from* here (see each export's `@source`). At the pinned commit it does **not**
  yet `import` `mufflyaccess`; its matches below are the **local originals** the
  SSOT was extracted from. It is the next adoption target, not yet a consumer.
- **`twostep` — consumer.** Imports `mufflyaccess` (pinned in `renv.lock`,
  declared in `DESCRIPTION`). Files like `R/contour_bands.R`,
  `R/access_categories.R`, `R/access_thresholds.R`, and
  `R/accessibility_stratification.R` are now **shims**: they
  `library(mufflyaccess)` and re-expose the promoted symbols, so bare names in
  `twostep` resolve to the package namespace. A `test-mufflyaccess-consistency.R`
  asserts each symbol comes from `environmentName == "mufflyaccess"`.
- **`cliff` — consumer.** Imports `mufflyaccess`; `R/safe_divide.R` is a shim over
  the safe-division family, guarded by its own consistency test.

Legend: **✅ consumes the SSOT** &nbsp;·&nbsp; **∘ local original** (present, but the
repo doesn't import the package) &nbsp;·&nbsp; **— not referenced**.

## Access bands, categories & thresholds

| Export | isochrones | twostep | cliff |
|---|:--:|:--:|:--:|
| `CANONICAL_BANDS` | ∘ | ✅ | — |
| `PRIMARY_ACCESS_BAND_MIN` | — | ✅ | — |
| `PRIMARY_ACCESS_BAND_SEC` | — | ✅ | — |
| `get_canonical_bands` | ∘ | ✅ | — |
| `get_primary_access_band` | — | ✅ | — |
| `DENOMINATOR_CATEGORY` | — | ✅ | — |
| `TRACT_REACHED_COVERAGE_PCT` | — | ✅ | — |

## Census denominators & geography

| Export | isochrones | twostep | cliff |
|---|:--:|:--:|:--:|
| `ACS2020_CONUS_FEMALE_POP` | — | ✅ | — |
| `TOTAL_FEMALE_VAR` | ∘ | ✅ | — |
| `RACE_FEMALE_VARS` | ∘ | ✅ | — |
| `CONUS_STATE_FIPS` | ∘ | ✅ | — |
| `CONUS_STATE_ABBR` | — | — | — |
| `NON_CONTIGUOUS_FIPS` | ∘ | ✅ | — |
| `NON_CONTIGUOUS_CODES` | ∘ | ✅ | — |

## Rurality (RUCA)

| Export | isochrones | twostep | cliff |
|---|:--:|:--:|:--:|
| `RUCA_NONMETRO_MIN` | — | ✅ | — |
| `rurality_from_ruca` | ∘ | ✅ | — |

## Accessibility-disparity statistics

| Export | isochrones | twostep | cliff |
|---|:--:|:--:|:--:|
| `weighted_mean_all` | ∘ | ✅ | — |
| `zero_access_share` | ∘ | ✅ | — |
| `mc_weighted_ci` | ∘ | ✅ | — |
| `annual_trend` | ∘ | ✅ | — |
| `tract_vintage_of` | ∘ | ✅ | — |
| `acs_year_of` | ∘ | ✅ | — |

## Safe-division family

| Export | isochrones | twostep | cliff |
|---|:--:|:--:|:--:|
| `safe_divide` | ∘ | — | ✅ |
| `safe_divide_manu` | ∘ | — | ✅ |
| `safe_pct_manu` | ∘ | — | ✅ |
| `safe_percent` | ∘ | — | ✅ |
| `safe_rate` | ∘ | — | ✅ |
| `safe_ratio` | ∘ | — | ✅ |

## URPS workforce-projection contract (producer-driven)

Unlike the access constants above — which flow *out* of `mufflyaccess` into
`twostep` — the workforce-projection family is a **producer→SSOT** contract: the
model lives in `cliff`, and `mufflyaccess` owns only the vocabulary and the
validators. `cliff`'s `scripts/urps_projection/build_urps_projection.R` runs the
workforce engine and calls back into these exports to key its output on the
shared scenario enum and to fail-loud validate the long table before it is
committed. So `cliff`'s relationship here is **consumer of the contract, producer
of the artifact** — the mirror image of the count contract (`urps_count()` etc.),
where `isochrones` is the producer.

| Export family | Role | cliff | isochrones | twostep |
|---|---|:--:|:--:|:--:|
| Scenario dictionary (`urps_scenarios`, `urps_scenario`, `urps_scenario_ids`, `is_urps_scenario`, `validate_urps_scenarios`, `URPS_SCENARIO_REGISTRY_VERSION`) | Names the projection's scenario column | ✅ | — | — |
| Projection contract (`urps_projection_schema`, `validate_urps_projection`, `read_urps_projection`, `URPS_PROJECTION_CONTRACT_VERSION`) | Validates cliff's emitted long table | ✅ | — | — |
| Clinical-FTE supply (`urps_effective_fte`, `urps_fte_weight`, `urps_fte_scale`, `URPS_FTE_PATHWAY_CLINICAL_TIME`, …) | Fills `supply_clinical_fte` | ✅ | — | — |
| Demand + gap (`urps_demand_fte`, `urps_gap_fte`, `urps_demand_params`, …) | Fills `demand_clinical_fte` / `gap_fte` (NA pre-calibration) | ✅ | — | — |
| Workforce flows (`urps_retirement_hazard`, `urps_entrants`, `urps_apply_lfp`, …) | Stock-and-flow primitives for the recurrence | ✅ | — | — |
| Geographic allocation + parameter CI (`urps_allocate_national`, `urps_projection_ci`, …) | State split / bootstrap intervals | ✅ | — | — |

> These rows are a **curated** interpretation, not raw `usage_matrix.sh` output:
> the projection producer lives in a `scripts/` path the matrix script does not
> scan, and the consume-direction is inverted (cliff calls the validators rather
> than re-exposing constants via a shim). Re-confirm against
> `cliff/scripts/urps_projection/` when the producer moves.

## Margins of error & PFD prevalence — currently unconsumed

These exports are in the SSOT but not referenced by any of the three repos at
their pinned commits — they were added ahead of adoption. Worth a periodic look:
either a consumer still holds a private copy that should become a shim, or the
export is genuinely ahead of its callers.

| Export | isochrones | twostep | cliff | Note |
|---|:--:|:--:|:--:|---|
| `ACS_MOE_Z90` | — | — | — | ACS MOE multipliers; not yet wired into a shim. |
| `CI_Z95` | — | — | — | |
| `MOE90_TO_CI95_FACTOR` | — | — | — | |
| `CONUS_STATE_ABBR` | — | — | — | Derived from `CONUS_STATE_FIPS`; no consumer references the abbrev form yet. |
| `WU2014_PFD_PREVALENCE` | — | — | — | The 65+ **access** demand denominator (isochrones/twostep target). |
| `pfd_prevalence` | — | — | —¹ | |
| `pfd_prevalence_acs_bands` | — | — | — | |

> ¹ **Name-collision caveat.** A raw grep flags `pfd_prevalence` in `cliff`, but
> those hits reference `cliff`'s **local** `R/pfd_prevalence.R` — the full-age
> **Nygaard-2008** projection curve (`pfd_prevalence_by_age()`), a *different
> source and cohort* from this package's Wu-2014 table. This is exactly the
> scope boundary the package documents: `cliff` does **not** consume the SSOT
> `pfd_prevalence()`. The curated table above records the boundary; the raw
> `usage_matrix.sh` output cannot, which is why the two are kept separate.

## Regenerating

```sh
# from the mufflyaccess repo root, with the consumer repos checked out nearby:
tools/usage_matrix.sh ../isochrones ../twostep ../cliff
```

The script reads the export list from `NAMESPACE` and greps each symbol across
every repo's `*.R` / `*.Rmd` sources, emitting a raw presence matrix (`*` =
importing repo references it, `o` = non-importing repo references it, `.` =
absent). Re-run it after promoting a new constant or when a consumer adopts the
package, then fold any changes — and any name-collision caveats like the one
above — back into this file.
