# Monte-Carlo CI for a population-weighted accessibility statistic. Redraws weights ~ Normal(est, se) B times (unbiased: point estimate lies inside its interval).

Monte-Carlo CI for a population-weighted accessibility statistic.
Redraws weights ~ Normal(est, se) B times (unbiased: point estimate lies
inside its interval).

## Usage

``` r
mc_weighted_ci(
  access,
  est,
  se,
  stat = c("mean", "zero"),
  B = 2000L,
  probs = c(0.025, 0.975),
  seed = 1L
)
```

## Arguments

- access:

  numeric accessibility values.

- est:

  numeric weight estimates.

- se:

  numeric weight standard errors (ACS MOE / z90).

- stat:

  "mean"/"zero".

- B:

  draws.

- probs:

  interval quantiles.

- seed:

  RNG seed.

## Value

named numeric c(point, lo, hi).

## See also

[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md)

Other accessibility-disparity statistics:
[`acs_year_of()`](https://mufflyt.github.io/mufflyaccess/reference/acs_year_of.md),
[`annual_trend()`](https://mufflyt.github.io/mufflyaccess/reference/annual_trend.md),
[`rurality_from_ruca()`](https://mufflyt.github.io/mufflyaccess/reference/rurality_from_ruca.md),
[`tract_vintage_of()`](https://mufflyt.github.io/mufflyaccess/reference/tract_vintage_of.md),
[`weighted_mean_all()`](https://mufflyt.github.io/mufflyaccess/reference/weighted_mean_all.md),
[`zero_access_share()`](https://mufflyt.github.io/mufflyaccess/reference/zero_access_share.md)

## Examples

``` r
# with zero standard errors the interval collapses to the point estimate
mc_weighted_ci(c(1, 3), est = c(1, 3), se = c(0, 0), B = 100)
#> point    lo    hi 
#>   2.5   2.5   2.5 
# -> c(point = 2.5, lo = 2.5, hi = 2.5)
if (FALSE) { # \dontrun{
# real use: ACS estimates with their MOE-derived standard errors
mc_weighted_ci(access, est = pop_est, se = pop_moe / ACS_MOE_Z90)
} # }
```
