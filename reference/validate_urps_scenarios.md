# Validate that scenarios are registered (fail loud)

Guard for a consumer's projection output: assert that every
`scenario_id` used is defined in this registry, so an ad-hoc or
misspelled scenario can never silently enter a published projection
table. Accepts either a character vector of ids or a `data.frame`
carrying a `scenario_id` column.

## Usage

``` r
validate_urps_scenarios(x)
```

## Arguments

- x:

  A character vector of scenario ids, or a `data.frame` with a
  `scenario_id` column.

## Value

Invisibly `TRUE`; otherwise stops, naming the unregistered id(s).

## See also

[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md)

Other URPS scenarios:
[`URPS_SCENARIO_REGISTRY_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_SCENARIO_REGISTRY_VERSION.md),
[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md)

## Examples

``` r
validate_urps_scenarios(c("baseline", "fellowship_plus_10pct"))
validate_urps_scenarios(data.frame(scenario_id = "retire_2yr_earlier", value = 1))
try(validate_urps_scenarios("earlier_retirement")) # not a registered id
#> Error : [validate_urps_scenarios] unregistered scenario_id(s): earlier_retirement. Valid ids: baseline, retire_2yr_earlier, retire_5yr_earlier, retire_2yr_later, fellowship_plus_10pct, fellowship_constrained, lower_late_career_fte, demand_insurance_expansion, demand_obesity_increase, demand_equity, demand_managed_care_increase, demand_retail_clinic_shift, combined_pessimistic, combined_investment.
```
