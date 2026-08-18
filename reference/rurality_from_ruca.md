# Map a USDA RUCA primary code to a binary rurality class. Metropolitan = primary RUCA 1..(RUCA_NONMETRO_MIN-1); Rural = RUCA_NONMETRO_MIN..10.

Map a USDA RUCA primary code to a binary rurality class. Metropolitan =
primary RUCA 1..(RUCA_NONMETRO_MIN-1); Rural = RUCA_NONMETRO_MIN..10.

## Usage

``` r
rurality_from_ruca(code)
```

## Arguments

- code:

  integer-coercible RUCA primary code(s).

## Value

character "Metropolitan"/"Rural" (NA for NA/invalid codes).

## See also

[RUCA_NONMETRO_MIN](https://mufflyt.github.io/mufflyaccess/reference/RUCA_NONMETRO_MIN.md)

Other accessibility-disparity statistics:
[`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md),
[`annual_trend()`](https://mufflyt.github.io/mufflyaccess/reference/annual_trend.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
[`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md),
[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md)

Other rurality:
[`RUCA_NONMETRO_MIN`](https://mufflyt.github.io/mufflyaccess/reference/RUCA_NONMETRO_MIN.md)

## Examples

``` r
rurality_from_ruca(c(1, 4, 10, NA))
#> [1] "Metropolitan" "Rural"        "Rural"        NA            
# "Metropolitan" (1-3), "Rural" (>=4), "Rural" (10), NA
```
