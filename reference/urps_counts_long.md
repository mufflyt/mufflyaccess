# The complete long URPS workforce table (all measures x geographies)

The complete long URPS workforce table (all measures x geographies)

## Usage

``` r
urps_counts_long()
```

## Value

A `data.frame` with columns
`year, measure, geography, board_pathway, n_active, n_ever_certified, n_retired, snapshot_date, source_sha256, method_version`,
plus `retirement_status`. When retirement is not observed (see
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md)),
`n_retired` is served as `NA_integer_` rather than the artifact's
placeholder `0`, so an unavailable count can never be mistaken for zero
departures.

## See also

[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
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
d <- urps_counts_long()
d[d$year == 2023 & d$geography == "national", c("measure", "board_pathway", "n_active")]
#>                   measure board_pathway n_active
#> 11 board_certified_active          ABOG     1027
#> 23 board_certified_active   ABU_NET_NEW      279
#> 35 board_certified_active ABOG_PLUS_ABU     1306
```
