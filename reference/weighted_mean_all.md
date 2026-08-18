# Population-weighted mean over all elements (sparse-group safe).

Population-weighted mean over all elements (sparse-group safe).

## Usage

``` r
weighted_mean_all(a, w)
```

## Arguments

- a:

  numeric values.

- w:

  numeric weights (same length as `a`).

## Value

weighted mean, or NA if the weights sum to 0 / non-finite.

## See also

[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md)

Other accessibility-disparity statistics:
[`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md),
[`annual_trend()`](https://mufflyt.github.io/mufflyaccess/reference/annual_trend.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
[`rurality_from_ruca()`](https://mufflyt.github.io/mufflyaccess/reference/rurality_from_ruca.md),
[`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md),
[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md)

## Examples

``` r
weighted_mean_all(c(1, 3), c(1, 3)) # 2.5  (population-weighted toward 3)
#> [1] 2.5
weighted_mean_all(1:3, c(0, 0, 0)) # NA_real_  (zero total weight)
#> [1] NA
```
