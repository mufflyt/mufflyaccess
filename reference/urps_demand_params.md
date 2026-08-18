# URPS healthcare use prediction equation parameters (skeleton)

The regression parameter skeleton for six URPS-relevant service types
following the IHS Markit HWMM specification:

|                             |                   |                |
|-----------------------------|-------------------|----------------|
| Service                     | Model             | Outcome        |
| Office visits               | Negative binomial | Annual count   |
| Outpatient visits           | Negative binomial | Annual count   |
| Home health visits          | Negative binomial | Annual count   |
| Hospitalization probability | Logistic          | Probability    |
| ED visit probability        | Logistic          | Probability    |
| Hospital length of stay     | Poisson           | Days/admission |

**Status:** `calibration_status = "not_calibrated"` – all beta columns
are `NA_real_`. The structure exists so cliff can wire
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md)
into the projection contract today. Coefficients populate when MEPS
2013-2017 or NAMCS restricted-use data are fitted for URPS / FPMRS
services.

**Covariates (columns `b_*`):** age, sex, race/ethnicity, BMI, smoking,
income (FPL category), insurance type, managed care enrollment, chronic
condition count, urban-rural. Reference encoding follows HWMM: female =
reference sex, non-Hispanic white = reference race,= 400% FPL =
reference income, private insurance = reference.

## Usage

``` r
urps_demand_params()
```

## Value

A `data.frame` with columns `service_type`, `model_form`,
`outcome_units`, covariate beta columns (`b_*`), `nb_theta`,
`calibration_scalar`, `data_source`, and `calibration_status`. Carries
attributes `source`, `formula_note`, and `covariate_reference`.

## See also

[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[URPS_DEMAND_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
urps_demand_params()
#>           service_type        model_form      outcome_units intercept b_age
#> 1         office_visit negative_binomial annual_visit_count        NA    NA
#> 2     outpatient_visit negative_binomial annual_visit_count        NA    NA
#> 3    home_health_visit negative_binomial annual_visit_count        NA    NA
#> 4 hospitalization_prob          logistic    probability_0_1        NA    NA
#> 5        ed_visit_prob          logistic    probability_0_1        NA    NA
#> 6         hospital_los           poisson days_per_admission        NA    NA
#>   b_sex_male b_race_black b_race_hispanic b_race_other b_bmi b_smoking_current
#> 1         NA           NA              NA           NA    NA                NA
#> 2         NA           NA              NA           NA    NA                NA
#> 3         NA           NA              NA           NA    NA                NA
#> 4         NA           NA              NA           NA    NA                NA
#> 5         NA           NA              NA           NA    NA                NA
#> 6         NA           NA              NA           NA    NA                NA
#>   b_income_low b_income_mid b_insurance_medicaid b_insurance_medicare
#> 1           NA           NA                   NA                   NA
#> 2           NA           NA                   NA                   NA
#> 3           NA           NA                   NA                   NA
#> 4           NA           NA                   NA                   NA
#> 5           NA           NA                   NA                   NA
#> 6           NA           NA                   NA                   NA
#>   b_insurance_uninsured b_managed_care b_chronic_count b_urban nb_theta
#> 1                    NA             NA              NA      NA       NA
#> 2                    NA             NA              NA      NA       NA
#> 3                    NA             NA              NA      NA       NA
#> 4                    NA             NA              NA      NA       NA
#> 5                    NA             NA              NA      NA       NA
#> 6                    NA             NA              NA      NA       NA
#>   calibration_scalar    data_source calibration_status
#> 1                  1 MEPS_2013_2017     not_calibrated
#> 2                  1 MEPS_2013_2017     not_calibrated
#> 3                  1 MEPS_2013_2017     not_calibrated
#> 4                  1 MEPS_2013_2017     not_calibrated
#> 5                  1 MEPS_2013_2017     not_calibrated
#> 6                  1 MEPS_2013_2017     not_calibrated
urps_demand_params()[, c("service_type", "model_form", "calibration_status")]
#>           service_type        model_form calibration_status
#> 1         office_visit negative_binomial     not_calibrated
#> 2     outpatient_visit negative_binomial     not_calibrated
#> 3    home_health_visit negative_binomial     not_calibrated
#> 4 hospitalization_prob          logistic     not_calibrated
#> 5        ed_visit_prob          logistic     not_calibrated
#> 6         hospital_los           poisson     not_calibrated
```
