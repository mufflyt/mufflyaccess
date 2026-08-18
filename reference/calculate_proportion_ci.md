# Wilson-score confidence interval for a single proportion

The Wilson interval is well-behaved for small samples and for
proportions near 0 or 1, which is why it is used here rather than the
Wald interval: a rural access-desert proportion is routinely both.

## Usage

``` r
calculate_proportion_ci(x, n, conf_level = 0.95)
```

## Arguments

- x:

  Successes (at-risk count).

- n:

  Sample size.

- conf_level:

  Confidence level (default 0.95).

## Value

List: `proportion`, `lower_ci`, `upper_ci` (proportions in `[0, 1]`),
`method`, `note`.

## See also

Other workforce statistics:
[`calculate_replacement_gap()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_replacement_gap.md),
[`calculate_rural_metro_comparison()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_rural_metro_comparison.md),
[`calculate_state_vulnerability()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_state_vulnerability.md),
[`calculate_two_prop_test()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_two_prop_test.md)

## Examples

``` r
calculate_proportion_ci(12, 40)
#> $proportion
#> [1] 0.3
#> 
#> $lower_ci
#> [1] 0.1807485
#> 
#> $upper_ci
#> [1] 0.4543002
#> 
#> $method
#> [1] "Wilson"
#> 
#> $note
#> [1] "95% confidence interval"
#> 
```
