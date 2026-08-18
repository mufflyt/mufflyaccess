# Schema of a URPS demand-model parameter artifact

The column contract a fitted (or example) demand-parameter table must
satisfy to be ingested by
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md).
It mirrors the structure
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)
returns, so a validated artifact is a drop-in for the NA skeleton once
real coefficients exist.

## Usage

``` r
urps_demand_params_schema()
```

## Value

A `data.frame` with one row per column: `column`, `type`, `required`,
and `description`.

## See also

[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
urps_demand_params_schema()
#>                   column      type required
#> 1           service_type character     TRUE
#> 2             model_form character     TRUE
#> 3          outcome_units character     TRUE
#> 4              intercept    double     TRUE
#> 5                  b_age    double     TRUE
#> 6             b_sex_male    double     TRUE
#> 7           b_race_black    double     TRUE
#> 8        b_race_hispanic    double     TRUE
#> 9           b_race_other    double     TRUE
#> 10                 b_bmi    double     TRUE
#> 11     b_smoking_current    double     TRUE
#> 12          b_income_low    double     TRUE
#> 13          b_income_mid    double     TRUE
#> 14  b_insurance_medicaid    double     TRUE
#> 15  b_insurance_medicare    double     TRUE
#> 16 b_insurance_uninsured    double     TRUE
#> 17        b_managed_care    double     TRUE
#> 18       b_chronic_count    double     TRUE
#> 19               b_urban    double     TRUE
#> 20              nb_theta    double     TRUE
#> 21    calibration_scalar    double     TRUE
#> 22           data_source character     TRUE
#> 23    calibration_status character     TRUE
#>                                                                             description
#> 1                                       One of the six URPS service types (unique key).
#> 2                      negative_binomial / logistic / poisson (fixed per service_type).
#> 3       Outcome unit label (annual_visit_count / probability_0_1 / days_per_admission).
#> 4          Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 5          Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 6          Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 7          Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 8          Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 9          Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 10         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 11         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 12         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 13         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 14         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 15         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 16         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 17         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 18         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 19         Regression coefficient (NA only when calibration_status = 'not_calibrated').
#> 20 Negative-binomial dispersion; non-NA (>0) for NB rows when calibrated, NA otherwise.
#> 21             Specialty x setting calibration scalar (> 0); see urps_demand_scalars().
#> 22                                         Fitting data source (e.g. 'MEPS_2013_2017').
#> 23                      One of: not_calibrated, calibrated, literature_proxy, example .
```
