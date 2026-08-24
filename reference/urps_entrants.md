# Board-certified URPS entrants for a single year

Board-certified URPS entrants for a single year

## Usage

``` r
urps_entrants(
  year,
  geography = "national",
  include_urology = FALSE,
  measure = "board_certified_active"
)
```

## Arguments

- year:

  Integer measure year. `board_certified_active` covers 2013-2023;
  `roster_snapshot` is the 2025 snapshot. A year outside a measure's
  window is a hard error.

- geography:

  `"national"` (default) or `"conus"`. Case-insensitive.

- include_urology:

  Single non-`NA` logical. `FALSE` (default) = ABOG only (`ABOG`
  pathway); `TRUE` = both-pathway ABOG + ABU (`ABOG_PLUS_ABU`).

- measure:

  `"board_certified_active"` (default; the active-in-year cohort) or
  `"roster_snapshot"` (the 2025 roster). Case-insensitive.

## Value

Integer count of entrants into the board-certified URPS stock in `year`
(`include_urology = FALSE` = ABOG pathway; `TRUE` = ABOG + ABU). See
[`urps_entry_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entry_counts.md)
for the full definition and caveats.

## See also

[`urps_entry_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entry_counts.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_abog_cert_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_abog_cert_status.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
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
urps_entrants(2019) # ABOG pathway
#> [1] 35
urps_entrants(2019, include_urology = TRUE) # ABOG + ABU
#> [1] 48
```
