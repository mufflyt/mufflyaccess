# Census tract boundary vintage for a study year (2010 tracts \<=2019, 2020 \>=2020).

Census tract boundary vintage for a study year (2010 tracts \<=2019,
2020 \>=2020).

## Usage

``` r
tract_vintage_of(year)
```

## Arguments

- year:

  integer-coercible study year(s).

## Value

integer 2010 or 2020, the tract-boundary vintage in force that year.

## See also

[`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md)

Other accessibility-disparity statistics:
[`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md),
[`annual_trend()`](https://mufflyt.github.io/mufflyaccess/reference/annual_trend.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
[`rurality_from_ruca()`](https://mufflyt.github.io/mufflyaccess/reference/rurality_from_ruca.md),
[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md)

## Examples

``` r
tract_vintage_of(c(2019, 2020)) # 2010, 2020  (boundary break at 2020)
#> [1] 2010 2020
```
