# One scenario's definition

Look up a single scenario by id and return its full definition as a
labelled list, so a caller never passes around a bare `scenario_id`
without its lever meaning. Unknown ids are a hard error listing the
valid ids.

## Usage

``` r
urps_scenario(scenario_id)
```

## Arguments

- scenario_id:

  A single registered scenario id (see
  [`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md)).

## Value

A named list: the row's fields (`scenario_id`, `family`, `label`, the
four lever fields, `requires_fte_model`, `description`) plus
`components` – the character vector of component scenario ids for a
`composite`, or `NULL` otherwise – and `registry_version`.

## See also

[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md)

Other URPS scenarios:
[`URPS_SCENARIO_REGISTRY_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_SCENARIO_REGISTRY_VERSION.md),
[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md)

## Examples

``` r
urps_scenario("fellowship_plus_10pct")
#> $scenario_id
#> [1] "fellowship_plus_10pct"
#> 
#> $family
#> [1] "entry"
#> 
#> $label
#> [1] "Fellowship output +10%"
#> 
#> $entrant_multiplier
#> [1] 1.1
#> 
#> $retirement_shift_years
#> [1] 0
#> 
#> $late_career_fte_factor
#> [1] 1
#> 
#> $late_career_fte_onset_age
#> [1] NA
#> 
#> $demand_obesity_prev_shift
#> [1] 0
#> 
#> $demand_insurance_expansion_factor
#> [1] 1
#> 
#> $demand_managed_care_factor
#> [1] 1
#> 
#> $demand_retail_clinic_share
#> [1] 0
#> 
#> $requires_fte_model
#> [1] FALSE
#> 
#> $requires_demand_model
#> [1] FALSE
#> 
#> $description
#> [1] "Annual entrants scaled by 1.10 -- a 10% expansion of fellowship output."
#> 
#> $registry_version
#> [1] "1.2.0"
#> 
urps_scenario("combined_pessimistic")$components
#> [1] "retire_2yr_earlier"     "fellowship_constrained" "lower_late_career_fte" 
try(urps_scenario("no_such_scenario")) # hard error
#> Error : [urps_scenario] unknown scenario_id 'no_such_scenario'; use one of baseline, retire_2yr_earlier, retire_5yr_earlier, retire_2yr_later, fellowship_plus_10pct, fellowship_constrained, lower_late_career_fte, demand_insurance_expansion, demand_obesity_increase, demand_equity, demand_managed_care_increase, demand_retail_clinic_shift, combined_pessimistic, combined_investment.
```
