# A wide URPS workforce slice for one measure x geography

One row per year for the chosen `measure`/`geography`, pivoted wide
across pathways, with explicit missingness columns. Defaults to the
canonical `board_certified_active` / `national` slice (years 2013-2023).
Use
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md)
for the complete long table across all cells, or
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
for a single value.

## Usage

``` r
urps_counts(measure = "board_certified_active", geography = "national")
```

## Arguments

- measure:

  `"board_certified_active"` (default) or `"roster_snapshot"`.
  Case-insensitive.

- geography:

  `"national"` (default) or `"conus"`. Case-insensitive.

## Value

A `data.frame` with one row per measure year and columns:

- year, measure, geography:

  the slice keys

- abog_active, abu_net_new, combined_active:

  counts per pathway (`combined_active == abog_active + abu_net_new`)

- measure_year:

  alias of `year`, to keep the measure year distinct from the snapshot
  date

- snapshot_date:

  source roster `Date`

- method_version, source_sha256:

  provenance

- abog_active_status, abu_net_new_status, combined_active_status:

  `"observed"` / `"derived"` / `"unavailable"` – so `NA` is never
  mistaken for a genuine zero

## See also

[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
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
urps_counts() # board_certified_active / national
#>    year                measure geography abog_active abu_net_new
#> 1  2013 board_certified_active  national         471         184
#> 2  2014 board_certified_active  national         637         193
#> 3  2015 board_certified_active  national         724         208
#> 4  2016 board_certified_active  national         750         218
#> 5  2017 board_certified_active  national         780         221
#> 6  2018 board_certified_active  national         814         227
#> 7  2019 board_certified_active  national         849         240
#> 8  2020 board_certified_active  national         852         247
#> 9  2021 board_certified_active  national         924         256
#> 10 2022 board_certified_active  national         966         268
#> 11 2023 board_certified_active  national        1027         279
#>    combined_active measure_year snapshot_date        method_version
#> 1              655         2013    2026-07-22 urps-workforce-v3.0.0
#> 2              830         2014    2026-07-22 urps-workforce-v3.0.0
#> 3              932         2015    2026-07-22 urps-workforce-v3.0.0
#> 4              968         2016    2026-07-22 urps-workforce-v3.0.0
#> 5             1001         2017    2026-07-22 urps-workforce-v3.0.0
#> 6             1041         2018    2026-07-22 urps-workforce-v3.0.0
#> 7             1089         2019    2026-07-22 urps-workforce-v3.0.0
#> 8             1099         2020    2026-07-22 urps-workforce-v3.0.0
#> 9             1180         2021    2026-07-22 urps-workforce-v3.0.0
#> 10            1234         2022    2026-07-22 urps-workforce-v3.0.0
#> 11            1306         2023    2026-07-22 urps-workforce-v3.0.0
#>                                                       source_sha256
#> 1  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 2  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 3  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 4  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 5  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 6  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 7  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 8  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 9  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 10 a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 11 a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#>    abog_active_status abu_net_new_status combined_active_status
#> 1            observed           observed                derived
#> 2            observed           observed                derived
#> 3            observed           observed                derived
#> 4            observed           observed                derived
#> 5            observed           observed                derived
#> 6            observed           observed                derived
#> 7            observed           observed                derived
#> 8            observed           observed                derived
#> 9            observed           observed                derived
#> 10           observed           observed                derived
#> 11           observed           observed                derived
utils::tail(urps_counts("board_certified_active", "conus"), 3)
#>    year                measure geography abog_active abu_net_new
#> 9  2021 board_certified_active     conus         924         255
#> 10 2022 board_certified_active     conus         965         266
#> 11 2023 board_certified_active     conus        1026         277
#>    combined_active measure_year snapshot_date        method_version
#> 9             1179         2021    2026-07-22 urps-workforce-v3.0.0
#> 10            1231         2022    2026-07-22 urps-workforce-v3.0.0
#> 11            1303         2023    2026-07-22 urps-workforce-v3.0.0
#>                                                       source_sha256
#> 9  a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 10 a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#> 11 a6aad44a8676be79c035b03ac639ff813fa65cb29a356c378abcea1df6c712af
#>    abog_active_status abu_net_new_status combined_active_status
#> 9            observed           observed                derived
#> 10           observed           observed                derived
#> 11           observed           observed                derived
```
