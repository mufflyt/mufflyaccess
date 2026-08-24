# Compare two URPS workforce artifacts (release-to-release drift)

Structured diff of two artifact directories: provider additions /
removals (by NPI, when the provider parquet is readable), changed
certification years, changed geography assignments, changed pathway
assignments, and changed count cells. A non-empty diff means the
candidate release must not be adopted without reviewed, accepted drift.

## Usage

``` r
compare_urps_artifacts(old, candidate)
```

## Arguments

- old, candidate:

  Artifact directories to compare (`old` = current, `candidate` =
  proposed).

## Value

A named list; provider-level fields are populated only when the provider
parquet is readable (arrow / nanoparquet):

- added_providers, removed_providers:

  NPIs gained / dropped

- changed_certification_year, changed_geography, changed_pathway:

  NPIs whose attribute changed

- changed_counts:

  `year|measure|geography|pathway` keys whose count changed

## See also

[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md)

Other URPS workforce:
[`urps_abog_cert_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_abog_cert_status.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
[`urps_entrants()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entrants.md),
[`urps_entry_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entry_counts.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md),
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
if (FALSE) { # \dontrun{
drift <- compare_urps_artifacts("artifacts/v3.0.0", "artifacts/candidate")
if (length(drift$changed_counts)) stop("counts changed; review before adopting")
} # }
```
