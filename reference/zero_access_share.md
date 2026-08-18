# Zero-access share (percent of weighted population with access EXACTLY 0).

Zero-access share (percent of weighted population with access EXACTLY
0).

## Usage

``` r
zero_access_share(access, w)
```

## Arguments

- access:

  numeric accessibility values.

- w:

  numeric weights.

## Value

percent in `[0,100]` under non-negative weights, or NA.

## See also

[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md)

Other accessibility-disparity statistics:
[`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md),
[`annual_trend()`](https://mufflyt.github.io/mufflyaccess/reference/annual_trend.md),
[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
[`rurality_from_ruca()`](https://mufflyt.github.io/mufflyaccess/reference/rurality_from_ruca.md),
[`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md),
[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md)

## Examples

``` r
# 40 of 50 weighted population lives where access == 0  -> 80%
zero_access_share(c(0, 5, 0), c(10, 10, 30)) # 80
#> [1] 80
zero_access_share(c(1, 2, 3), c(1, 1, 1)) # 0  (nobody at exactly 0)
#> [1] 0
```
