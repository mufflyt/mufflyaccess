# Retrieve demand lever settings for a scenario (cliff integration helper)

Returns the four demand lever values for a registered scenario as a
named list, suitable for passing directly to
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md).
This is the demand-side counterpart to
[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md):
cliff calls this once per scenario to get the full demand lever bundle.

## Usage

``` r
urps_demand_levers(scenario_id)
```

## Arguments

- scenario_id:

  A registered scenario id (see
  [`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md)).

## Value

A named list with elements `demand_obesity_prev_shift`,
`demand_insurance_expansion_factor`, `demand_managed_care_factor`, and
`demand_retail_clinic_share`. Also carries `scenario_id`,
`requires_demand_model`, and `registry_version`.

## Details

**Lever semantics:**

- `demand_obesity_prev_shift`:

  Percentage-point shift in population obesity prevalence applied on top
  of baseline trends. Positive = higher obesity, increasing PFD
  incidence and visit rates.

- `demand_insurance_expansion_factor`:

  Multiplier on the utilization contribution of previously uninsured /
  underinsured persons. \> 1 means more demand from insurance expansion.

- `demand_managed_care_factor`:

  Multiplier on total physician demand from changes in HMO/ACO
  gatekeeping intensity. \< 1 means managed care reduces specialist
  referrals and direct access.

- `demand_retail_clinic_share`:

  Fraction of office-visit demand shifted to retail health clinics
  (staffed by APRNs/PAs for lower-acuity conditions). Reduces URPS
  physician demand proportionally.

## See also

[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
urps_demand_levers("baseline")
#> $scenario_id
#> [1] "baseline"
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
#> $requires_demand_model
#> [1] FALSE
#> 
#> $registry_version
#> [1] "1.2.0"
#> 
urps_demand_levers("demand_managed_care_increase")
#> $scenario_id
#> [1] "demand_managed_care_increase"
#> 
#> $demand_obesity_prev_shift
#> [1] 0
#> 
#> $demand_insurance_expansion_factor
#> [1] 1
#> 
#> $demand_managed_care_factor
#> [1] 0.85
#> 
#> $demand_retail_clinic_share
#> [1] 0
#> 
#> $requires_demand_model
#> [1] TRUE
#> 
#> $registry_version
#> [1] "1.2.0"
#> 
urps_demand_levers("demand_retail_clinic_shift")
#> $scenario_id
#> [1] "demand_retail_clinic_shift"
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
#> [1] 0.1
#> 
#> $requires_demand_model
#> [1] TRUE
#> 
#> $registry_version
#> [1] "1.2.0"
#> 
```
