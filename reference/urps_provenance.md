# Provenance / manifest for the URPS workforce SSOT

Everything needed to cite or audit the served numbers: contract /
artifact versions, the measures and geographies, the snapshot date, the
active-in-year and deduplication definitions, the source hash and git
commit, the disclosure-ready source wording, release-readiness flags,
and the recorded retired cells.

## Usage

``` r
urps_provenance(detailed = FALSE)
```

## Arguments

- detailed:

  If `TRUE`, add the nested `detail` element (see **Value**) with the
  full source-to-artifact provenance chain and a live integrity check.
  Default `FALSE` returns the stable summary only.

## Value

A named list:

- artifact_version, contract_version:

  version strings (e.g. `"3.0.0"`)

- artifact_source:

  `"external"` or `"bundled_bootstrap"`

- canonical_release, suitable_for_release:

  release-readiness flags

- canonical_2023_estimand:

  human-readable canonical-cell statement

- external_artifact_error:

  `NULL`, or the fallback reason

- measure_years:

  integer vector (2013:2023)

- measures, geographies, boards:

  the published dimensions

- snapshot_date:

  a `Date`; distinct from the measure year

- roster_reflects_certifications_through:

  last cert year in the roster

- geographic_scope, active_in_year_definition, deduplication_rule:

  definitional metadata

- source_sha256, source_git_commit, git_commit_semantics:

  source integrity + commit provenance

- source_description, source_systems:

  disclosure-ready source wording

- retired_cells:

  cells retired by an earlier contract (see
  [`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md))

- method_version, package_version:

  producer + installed package versions

With `detailed = TRUE`, one extra element `detail` – a nested list
carrying the full, verifiable provenance chain:

- artifact_dir, created_at:

  served directory and artifact build time

- measure_year, model_baseline_year, roster_snapshot_date:

  the three distinct years, kept separate

- geography_resolution_rule, state_source_counts:

  how each provider's state (hence CONUS membership) was resolved, and
  from which source

- cohort_definition:

  the URPS-subspecialty-cert basis: real cert dates, the
  fellowship-proxy fallbacks, and how many providers used each

- provider_snapshot:

  grain and the reconstruction counts (`rows_national`,
  `rows_active_2023`, future certifications)

- source_files:

  a `data.frame(name, path, sha256)` of the enriched source rosters

- combined_source_sha256, output_files:

  the combined source hash and the produced-artifact hashes

- integrity:

  a **live** check – the served CSV / parquet SHA-256 recomputed and
  compared to the manifest (`*_verified` is `TRUE`/`FALSE`, or `NA` when
  `digest` is unavailable)

- known_limitations:

  the producer's documented caveats

## Details

`artifact_source` is `"external"` when a released artifact is served and
`"bundled_bootstrap"` otherwise – including after a silent option/env
fallback, whose reason is then in `external_artifact_error`.
`canonical_release` / `suitable_for_release` are `FALSE` for the
bootstrap. Accessing this on an unusable external source emits a warning
(see
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md)).

## See also

[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_abog_cert_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_abog_cert_status.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
[`urps_entrants()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entrants.md),
[`urps_entry_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entry_counts.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md),
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
urps_provenance()$canonical_2023_estimand
#> [1] "board_certified_active / national = 1306"
urps_provenance()[c("contract_version", "artifact_source", "canonical_release")]
#> $contract_version
#> [1] "3.0.0"
#> 
#> $artifact_source
#> [1] "bundled_bootstrap"
#> 
#> $canonical_release
#> [1] FALSE
#> 

# the full chain, with a live SHA-256 integrity check of the served bytes:
d <- urps_provenance(detailed = TRUE)$detail
d$source_files # enriched rosters + hashes
#>             name                                             path
#> 1  abog_enriched cliff/data/abog_all_urps_ENRICHED_2026-07-22.csv
#> 2   abu_enriched  cliff/data/abu_all_urps_ENRICHED_2026-07-22.csv
#> 3 canonical_abog data/abog_pipeline/canonical_abog_npi_LATEST.rds
#>                                                             sha256
#> 1 96a9be0bfc73ceaac2226fa146d3b2446b6d86535e0729850724344dc650e4c9
#> 2 5ad396280f28992ff22f0d500938f2f3425e14fff186120d0d316c262e9165d0
#> 3 d8436ef267128c21c03303c1fdbd28ed4e6a64b2b856acc43759f4203b6b0a08
d$cohort_definition$source_counts # how the active cohort was dated
#> $abog_primary_plus_3yr_fellowship
#> [1] 47
#> 
#> $abog_sub1startdate
#> [1] 984
#> 
#> $abu_primary_plus_2yr_fellowship
#> [1] 308
#> 
d$integrity$counts_csv_verified # TRUE: served bytes match the manifest
#> [1] TRUE
```
