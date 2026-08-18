# Is a value a registered scenario id? (vectorised predicate)

A non-erroring, vectorised membership test against the registry – the
building block for a fail-loud guard or a filter.

## Usage

``` r
is_urps_scenario(x)
```

## Arguments

- x:

  A character vector of candidate ids.

## Value

A logical vector the same length as `x` (`NA` in, `FALSE` out).

## See also

[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md)

Other URPS scenarios:
[`URPS_SCENARIO_REGISTRY_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_SCENARIO_REGISTRY_VERSION.md),
[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md)

## Examples

``` r
is_urps_scenario(c("baseline", "typo", NA)) # TRUE FALSE FALSE
#> [1]  TRUE FALSE FALSE
```
