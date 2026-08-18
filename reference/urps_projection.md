# The canonical URPS supply projection

The published URPS projection – baseline headcount, horizon headcount
with and without the entry ramp, interval, entrants, exits and the
replacement ratio – served from the bundled artifact so consumers stop
copying the producing repository's CSVs.

## Usage

``` r
urps_projection(
  scenario = "baseline",
  geography = "national",
  pathway = "ABOG_PLUS_ABU"
)
```

## Arguments

- scenario:

  Scenario id; only `"baseline"` is currently published.

- geography:

  `"national"` (default) or `"conus"`.

- pathway:

  Board pathway; only `"ABOG_PLUS_ABU"` is currently published.

## Value

A one-row `data.frame`. Key columns: `baseline_year`,
`baseline_headcount`, `horizon_year`, `projected_headcount`,
`projected_headcount_ramped`, `lower_95`, `upper_95`, `annual_entrants`,
`mean_annual_exits`, `replacement_ratio`.

## Details

This is the reviewed RESULT of cliff's projection, not a re-run of it.
Use
[`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md)
and
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)
when you have your own projection table to check against the contract;
use this when you want the published numbers.

`replacement_ratio` is `annual_entrants / mean_annual_exits`, and
`baseline_headcount` is checked against
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
on every call, so the projection can never start from a number the SSOT
does not serve.

`projected_headcount` is the immediate-entry projection. The
entry-ramped variant (`projected_headcount_ramped`) defers new entrants
over the observed certification-to-practice curve and is reported as a
sensitivity, not the headline.

## See also

[`urps_active_ages()`](https://mufflyt.github.io/mufflyaccess/reference/urps_active_ages.md)
for the cohort it projects,
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
for the baseline it must agree with,
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)
for checking your own table.

Other URPS SSOT:
[`urps_active_ages()`](https://mufflyt.github.io/mufflyaccess/reference/urps_active_ages.md)

## Examples

``` r
p <- urps_projection()
p$baseline_headcount
#> [1] 1306
p$replacement_ratio
#> [1] 5.384894
```
