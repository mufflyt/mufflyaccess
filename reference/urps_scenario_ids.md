# The registered scenario ids (the enum)

The character vector of valid `scenario_id` values – the domain a
consumer validates its projection scenarios against.

## Usage

``` r
urps_scenario_ids()
```

## Value

A character vector of scenario ids.

## See also

[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md)

Other URPS scenarios:
[`URPS_SCENARIO_REGISTRY_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_SCENARIO_REGISTRY_VERSION.md),
[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md)

## Examples

``` r
urps_scenario_ids()
#>  [1] "baseline"                     "retire_2yr_earlier"          
#>  [3] "retire_5yr_earlier"           "retire_2yr_later"            
#>  [5] "fellowship_plus_10pct"        "fellowship_constrained"      
#>  [7] "lower_late_career_fte"        "demand_insurance_expansion"  
#>  [9] "demand_obesity_increase"      "demand_equity"               
#> [11] "demand_managed_care_increase" "demand_retail_clinic_shift"  
#> [13] "combined_pessimistic"         "combined_investment"         
```
