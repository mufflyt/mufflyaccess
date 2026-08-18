# ACS 5-year data year for a study year (clamped to the 2013-2022 window).

ACS 5-year data year for a study year (clamped to the 2013-2022 window).

## Usage

``` r
acs_year_of(year)
```

## Arguments

- year:

  integer-coercible study year(s).

## Value

integer ACS data end-year(s), clamped to `[2013, 2022]`.

## See also

[`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md)

Other accessibility-disparity statistics:
[`annual_trend()`](https://mufflyt.github.io/mufflyaccess/reference/annual_trend.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
[`rurality_from_ruca()`](https://mufflyt.github.io/mufflyaccess/reference/rurality_from_ruca.md),
[`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md),
[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md)

## Examples

``` r
acs_year_of(c(2011, 2018, 2025)) # 2013, 2018, 2022  (clamped to the window)
#> [1] 2013 2018 2022
```
