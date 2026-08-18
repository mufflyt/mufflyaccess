# OLS temporal trend of an annual series (95% t-interval on the slope).

OLS temporal trend of an annual series (95% t-interval on the slope).

## Usage

``` r
annual_trend(year, value)
```

## Arguments

- year:

  integer years.

- value:

  numeric annual estimates.

## Value

named numeric c(slope, lo, hi, p). All NA when fewer than 3 complete
year/value pairs are supplied.

## See also

Other accessibility-disparity statistics:
[`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
[`rurality_from_ruca()`](https://mufflyt.github.io/mufflyaccess/reference/rurality_from_ruca.md),
[`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md),
[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md)

## Examples

``` r
# rising ~1.4 percentage points per year
annual_trend(2013:2016, c(10, 11, 13, 14))["slope"] # ~1.4
#> slope 
#>   1.4 
annual_trend(2013:2014, c(10, 12)) # all NA (need >=3 points)
#> slope    lo    hi     p 
#>    NA    NA    NA    NA 
```
