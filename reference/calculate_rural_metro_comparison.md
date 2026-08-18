# Rural-vs-metro at-risk comparison (rates, Wilson CIs, two-proportion test)

Bundles the two group rates, their Wilson CIs, and the two-proportion
test into one result, so a reported disparity always travels with the
interval and the test that qualify it.

## Usage

``` r
calculate_rural_metro_comparison(
  rural_at_risk,
  rural_total,
  metro_at_risk,
  metro_total
)
```

## Arguments

- rural_at_risk, rural_total:

  Rural at-risk count and denominator.

- metro_at_risk, metro_total:

  Metro at-risk count and denominator.

## Value

List: `rural`, `metro`, `comparison` (rate difference plus the test).

## See also

Other workforce statistics:
[`calculate_proportion_ci()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_proportion_ci.md),
[`calculate_replacement_gap()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_replacement_gap.md),
[`calculate_state_vulnerability()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_state_vulnerability.md),
[`calculate_two_prop_test()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_two_prop_test.md)

## Examples

``` r
calculate_rural_metro_comparison(30, 100, 40, 200)$comparison$rate_difference_pct
#> [1] 10
```
