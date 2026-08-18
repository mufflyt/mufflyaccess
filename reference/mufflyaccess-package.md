# mufflyaccess: canonical access, census-denominator, and geography constants (SSOT)

Single source of truth for the constants and pure statistics shared
across the OB/GYN subspecialty geographic-access projects (isochrones,
twostep, cliff). Every value carries provenance and fail-loud validation
that runs at package load, so the repositories cannot silently disagree
about the numbers behind a published statistic.

## Reference by domain

- **Access bands & thresholds** —
  [PRIMARY_ACCESS_BAND_MIN](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md),
  [PRIMARY_ACCESS_BAND_SEC](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_SEC.md),
  [CANONICAL_BANDS](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md),
  [DENOMINATOR_CATEGORY](https://mufflyt.github.io/mufflyaccess/reference/DENOMINATOR_CATEGORY.md),
  [TRACT_REACHED_COVERAGE_PCT](https://mufflyt.github.io/mufflyaccess/reference/TRACT_REACHED_COVERAGE_PCT.md),
  [`get_primary_access_band()`](https://mufflyt.github.io/mufflyaccess/reference/get_primary_access_band.md),
  [`get_canonical_bands()`](https://mufflyt.github.io/mufflyaccess/reference/get_canonical_bands.md)

- **Census denominators** —
  [ACS2020_CONUS_FEMALE_POP](https://mufflyt.github.io/mufflyaccess/reference/ACS2020_CONUS_FEMALE_POP.md),
  [TOTAL_FEMALE_VAR](https://mufflyt.github.io/mufflyaccess/reference/TOTAL_FEMALE_VAR.md),
  [RACE_FEMALE_VARS](https://mufflyt.github.io/mufflyaccess/reference/TOTAL_FEMALE_VAR.md)

- **Geography** —
  [CONUS_STATE_FIPS](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md),
  [CONUS_STATE_ABBR](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_ABBR.md),
  [NON_CONTIGUOUS_FIPS](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_FIPS.md),
  [NON_CONTIGUOUS_CODES](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_CODES.md)

- **Margins of error** —
  [ACS_MOE_Z90](https://mufflyt.github.io/mufflyaccess/reference/ACS_MOE_Z90.md),
  [CI_Z95](https://mufflyt.github.io/mufflyaccess/reference/ACS_MOE_Z90.md),
  [MOE90_TO_CI95_FACTOR](https://mufflyt.github.io/mufflyaccess/reference/ACS_MOE_Z90.md)

- **Rurality (RUCA)** —
  [RUCA_NONMETRO_MIN](https://mufflyt.github.io/mufflyaccess/reference/RUCA_NONMETRO_MIN.md),
  [`rurality_from_ruca()`](https://mufflyt.github.io/mufflyaccess/reference/rurality_from_ruca.md)

- **PFD prevalence** —
  [WU2014_PFD_PREVALENCE](https://mufflyt.github.io/mufflyaccess/reference/WU2014_PFD_PREVALENCE.md),
  [`pfd_prevalence()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence.md),
  [`pfd_prevalence_acs_bands()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence_acs_bands.md)

- **URPS workforce SSOT** —
  [`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
  [`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
  [`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
  [`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
  [`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
  [`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
  [`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
  [`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
  [`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md),
  [`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md);
  the deprecated
  [URPS_COUNT_ABOG_ONLY_2025](https://mufflyt.github.io/mufflyaccess/reference/urps_count_2025_deprecated.md)
  /
  [URPS_COUNT_ABOG_PLUS_ABU_2025](https://mufflyt.github.io/mufflyaccess/reference/urps_count_2025_deprecated.md)
  constants

- **URPS scenario dictionary** —
  [`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
  [`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
  [`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
  [`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
  [`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md),
  [URPS_SCENARIO_REGISTRY_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_SCENARIO_REGISTRY_VERSION.md)

- **URPS projection contract** —
  [`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md),
  [`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md),
  [`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md),
  [URPS_PROJECTION_CONTRACT_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_PROJECTION_CONTRACT_VERSION.md)

- **Accessibility statistics** —
  [`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
  [`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md),
  [`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
  [`annual_trend()`](https://mufflyt.github.io/mufflyaccess/reference/annual_trend.md),
  [`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md),
  [`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md)

- **Safe division** —
  [`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md)
  and its family

## The URPS workforce SSOT

isochrones builds and hashes the provider roster; mufflyaccess reads,
validates, and serves it; consumers call
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
and never derive a national count themselves. The served contract is
v3.0.0: the canonical 2023 estimand is
`board_certified_active / national` = **1306** (CONUS 1303), **1339** is
the 2025 `roster_snapshot`, and the retired v2.1.0 cells (1332 / 1329)
are surfaced only via
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md)
/
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md).
See `ARCHITECTURE.md`.

mufflyaccess also owns the **scenario dictionary**
([`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md)):
the single versioned vocabulary of named forward-projection scenarios
(baseline, earlier/later retirement, fellowship expansion/constraint,
reduced late-career FTE, and composites). It fixes each scenario's
*lever values* – the definition every repo agrees on and the enum a
projection table keys on – but never the projection model, which stays
in cliff.

The **projection contract**
([`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md))
is the second producer -\> SSOT contract, mirroring the count artifact:
cliff runs the workforce projection engine and emits a long table keyed
on `scenario_id`; mufflyaccess validates its schema, that every scenario
is registered, its internal consistency (95% bounds, the
`entrants - exits` flow identity), and a tie of the baseline-year
starting stock back to
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md).
mufflyaccess owns the contract and the checks, never the projection
model.

## Design

Values that must agree are *derived* from one another (never
duplicated), each `R/` file ends in a
[`stopifnot()`](https://rdrr.io/r/base/stopifnot.html) block that errors
at load on an impossible edit, and consumers pin a release commit rather
than tracking the branch. See the package README and `CONTRIBUTING.md`
for the promotion checklist and the consumer shim pattern.

## See also

Useful links:

- <https://github.com/mufflyt/mufflyaccess>

- Report bugs at <https://github.com/mufflyt/mufflyaccess/issues>

## Author

**Maintainer**: Tyler Muffly <tyler.muffly@dhha.org>
([ORCID](https://orcid.org/0000-0002-2044-1693))

Authors:

- Tyler Muffly <tyler.muffly@dhha.org>
  ([ORCID](https://orcid.org/0000-0002-2044-1693))
