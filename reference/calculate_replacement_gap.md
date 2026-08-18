# Subspecialty replacement-gap analysis (retirees vs fellowship graduates)

Projects `horizon_years` of graduates against projected retirements per
subspecialty and reports the net gap, the replacement ratio, and an
adequacy flag.

## Usage

``` r
calculate_replacement_gap(
  retirees_by_subspec,
  fellowship_grads,
  horizon_years = 5
)
```

## Arguments

- retirees_by_subspec:

  Data frame: `subspecialty`, `retiring_count`.

- fellowship_grads:

  Data frame: `subspecialty`, `graduates`, one row per observed year.

- horizon_years:

  Projection horizon in years (default 5).

## Value

List: `by_subspecialty` (data frame, ordered by subspecialty) and
`overall` (summary list).

## Details

`horizon_years` is a parameter, not a literal. The versions this
replaces multiplied by a hardcoded 5 next to a comment explaining that 5
was "horizon - reference", so moving the horizon silently left the
arithmetic behind.

A subspecialty with no matching graduate rows contributes 0 graduates,
not NA: absence of a fellowship is a real zero. A subspecialty with zero
retirements yields an NA replacement ratio rather than Inf, because
"nobody retiring" has no ratio to report.

## See also

Other workforce statistics:
[`calculate_proportion_ci()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_proportion_ci.md),
[`calculate_rural_metro_comparison()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_rural_metro_comparison.md),
[`calculate_state_vulnerability()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_state_vulnerability.md),
[`calculate_two_prop_test()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_two_prop_test.md)

## Examples

``` r
calculate_replacement_gap(
  data.frame(subspecialty = c("FPMRS", "GO"), retiring_count = c(50, 30)),
  data.frame(subspecialty = c("FPMRS", "FPMRS", "GO"), graduates = c(10, 12, 4))
)$overall$replacement_ratio
#> [1] 0.9375
```
