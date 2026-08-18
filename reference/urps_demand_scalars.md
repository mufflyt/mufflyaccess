# URPS specialty x setting calibration scalar table (skeleton)

Multiplicative scalars aligning MEPS-fitted visit predictions to
NAMCS/NHAMCS/NIS national survey totals, one per service setting. All
scalars are `1.0` until calibrated.

**How scalars compose with the regression:**

    predicted_visits(i, setting) =
      scalar(setting) * exp(intercept + b_age*age + ... + b_urban*urban)

The scalar is the ratio of the NAMCS/NHAMCS/NIS observed national total
to the aggregate MEPS-predicted total, holding the covariate
distribution fixed.

## Usage

``` r
urps_demand_scalars()
```

## Value

A `data.frame` with columns `specialty`, `setting`, `scalar`,
`calibration_source`, and `calibration_status`. Carries attributes
`source` and `formula_note`.

## See also

[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[URPS_DEMAND_SCALARS_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
urps_demand_scalars()
#>   specialty       setting scalar calibration_source calibration_status
#> 1      URPS        office      1         NAMCS_2023     not_calibrated
#> 2      URPS    outpatient      1          HCUP_SASD     not_calibrated
#> 3      URPS   home_health      1          MEPS_2023     not_calibrated
#> 4      URPS     inpatient      1      HCUP_NIS_2023     not_calibrated
#> 5      URPS            ed      1     NHAMCS_ED_2022     not_calibrated
#> 6      URPS retail_clinic      1         NAMCS_2023     not_calibrated
urps_demand_scalars()[, c("setting", "scalar", "calibration_status")]
#>         setting scalar calibration_status
#> 1        office      1     not_calibrated
#> 2    outpatient      1     not_calibrated
#> 3   home_health      1     not_calibrated
#> 4     inpatient      1     not_calibrated
#> 5            ed      1     not_calibrated
#> 6 retail_clinic      1     not_calibrated
```
