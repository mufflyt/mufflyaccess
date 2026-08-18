# Version of the URPS scenario registry

The semantic version of the scenario dictionary served by this package.
Bump it whenever a scenario is added, removed, or its lever definition
changes, so a downstream projection table can record exactly which
registry it was built against.

## Usage

``` r
URPS_SCENARIO_REGISTRY_VERSION
```

## Format

Length-1 character string (e.g. `"1.0.0"`).

## See also

[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md)

Other URPS scenarios:
[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md)

## Examples

``` r
URPS_SCENARIO_REGISTRY_VERSION
#> [1] "1.2.0"
```
