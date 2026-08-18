# OLS parameters for the URPS sex-stratified weekly patient care hours model

The quadratic regression coefficients fit separately for female and male
URPS providers, with the anchor points that define them and their
calibration status. These parameters are the input to
[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md)
and
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md).

## Usage

``` r
urps_fte_sex_hours_params()
```

## Value

A `data.frame` with columns `sex`, `intercept`, `b_age`, `c_age_sq`,
`anchor_age_lo`, `anchor_hours_lo`, `anchor_age_peak`,
`anchor_hours_peak`, `anchor_age_hi`, `anchor_hours_hi`, and
`calibration_status`. Carries attributes `source`, `formula`, and
`reference_hours`.

## Details

**Calibration:** coefficients are fit by quadratic regression to three
anchor points per sex (see `anchor_*` columns) derived from the ACOG
2021 Workforce Survey and AMA 2022 Benchmark Survey for OB/GYN
subspecialists. The `calibration_status` column is
`"calibrated_from_literature"` throughout; ABOG lapse records or a
URPS-specific practice survey would sharpen these estimates.

**Model:** `hours(age) = intercept + b_age * age + c_age_sq * age^2`.

**FTE weight:** `max(hours, 0) / URPS_FTE_REFERENCE_HOURS_PER_WEEK` (40
hrs/wk = 1.0 FTE).

## See also

[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md),
[URPS_FTE_SEX_HOURS_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_SEX_HOURS_VERSION.md),
[URPS_FTE_REFERENCE_HOURS_PER_WEEK](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md)

Other URPS FTE sex:
[`URPS_FTE_REFERENCE_HOURS_PER_WEEK`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md),
[`URPS_FTE_SEX_HOURS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_SEX_HOURS_VERSION.md),
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md),
[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md),
[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md),
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md)

## Examples

``` r
urps_fte_sex_hours_params()
#>      sex intercept    b_age    c_age_sq anchor_age_lo anchor_hours_lo
#> 1 female -41.87500 4.000000 -0.04500000            35              43
#> 2   male -39.21759 4.137037 -0.04537037            35              50
#>   anchor_age_peak anchor_hours_peak anchor_age_hi anchor_hours_hi
#> 1              45                47            65              28
#> 2              47                55            65              38
#>           calibration_status
#> 1 calibrated_from_literature
#> 2 calibrated_from_literature
attr(urps_fte_sex_hours_params(), "source")
#> [1] "ACOG 2021 Workforce Survey (weekly hours by age and sex, OB/GYN subspecialists); AMA 2022 Physician Practice Benchmark Survey (weekly patient care hours); IHS Markit HWMM v5.19.20 Exhibits 14-15 (OLS hours-worked model structure). Sharpen with: ABOG lapse/recertification panel or URPS practice survey."
```
