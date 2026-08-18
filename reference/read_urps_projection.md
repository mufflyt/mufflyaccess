# Read a URPS projection table (typed), optionally validating it

Read a projection CSV into a typed `data.frame` (coercing `year` to
integer and the numeric measure columns to double), then – by default –
validate it against the contract.

## Usage

``` r
read_urps_projection(path, validate = TRUE, ...)
```

## Arguments

- path:

  Path to the projection CSV.

- validate:

  If `TRUE` (default), run
  [`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)
  before returning.

- ...:

  Passed to
  [`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)
  (e.g. `baseline_tie`).

## Value

The projection `data.frame`.

## See also

[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md),
[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md)

Other URPS projection:
[`URPS_PROJECTION_CONTRACT_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_PROJECTION_CONTRACT_VERSION.md),
[`urps_gap_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_gap_fte.md),
[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md),
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)

## Examples

``` r
f <- system.file("extdata", "urps_projection_example.csv", package = "mufflyaccess")
str(read_urps_projection(f))
#> 'data.frame':    12 obs. of  13 variables:
#>  $ year                 : int  2025 2026 2027 2028 2025 2026 2027 2028 2025 2026 ...
#>  $ scenario_id          : chr  "baseline" "baseline" "baseline" "baseline" ...
#>  $ specialty            : chr  "URPS" "URPS" "URPS" "URPS" ...
#>  $ certification_pathway: chr  "ABOG_PLUS_ABU" "ABOG_PLUS_ABU" "ABOG_PLUS_ABU" "ABOG_PLUS_ABU" ...
#>  $ geography_type       : chr  "national" "national" "national" "national" ...
#>  $ geography_id         : chr  "US" "US" "US" "US" ...
#>  $ supply_headcount     : num  1339 1324 1307 1289 1339 ...
#>  $ supply_clinical_fte  : num  NA NA NA NA NA NA NA NA NA NA ...
#>  $ lower_95             : num  NA 1300 1281 1261 NA ...
#>  $ upper_95             : num  NA 1348 1333 1317 NA ...
#>  $ entrants             : num  NA 45 45 45 NA 45 45 45 NA 50 ...
#>  $ exits                : num  NA 60 62 63 NA 72 74 75 NA 60 ...
#>  $ net_change           : num  NA -15 -17 -18 NA -27 -29 -30 NA -10 ...
```
