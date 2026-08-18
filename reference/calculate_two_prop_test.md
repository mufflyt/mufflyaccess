# Two-proportion z-test with an n \>= 30 guard

Refuses to test (returning `method = "descriptive_only"`) when either
group is below `min_sample_size`, so a workforce comparison can never
report a significant p-value off a handful of physicians. The refusal is
a value in the result rather than a warning, so a caller that ignores it
still cannot read a p-value that does not exist.

## Usage

``` r
calculate_two_prop_test(x1, n1, x2, n2, min_sample_size = 30)
```

## Arguments

- x1, n1:

  Successes and total in group 1.

- x2, n2:

  Successes and total in group 2.

- min_sample_size:

  Minimum per-group n for an inferential test.

## Value

List with `method`, `p_value`, `p_value_formatted`, `significant`,
`note`, and (on a real test) `test_statistic`.

## See also

Other workforce statistics:
[`calculate_proportion_ci()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_proportion_ci.md),
[`calculate_replacement_gap()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_replacement_gap.md),
[`calculate_rural_metro_comparison()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_rural_metro_comparison.md),
[`calculate_state_vulnerability()`](https://mufflyt.github.io/mufflyaccess/reference/calculate_state_vulnerability.md)

## Examples

``` r
calculate_two_prop_test(12, 40, 20, 60)
#> $method
#> [1] "prop.test"
#> 
#> $p_value
#> [1] 0.8955568
#> 
#> $p_value_formatted
#> [1] "0.90"
#> 
#> $significant
#> [1] FALSE
#> 
#> $test_statistic
#> [1] 0.01723346
#> 
#> $note
#> [1] "Two-proportion z-test"
#> 
calculate_two_prop_test(2, 5, 3, 6)$method # "descriptive_only"
#> [1] "descriptive_only"
```
