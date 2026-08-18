# Predicted weekly patient care hours by age and sex

Evaluates the quadratic OLS model
`hours(age) = intercept + b_age * age + c_age_sq * age^2`. Vectorized
over both `age` and `sex` (recycled against each other, so a mixed-sex
cohort vector works directly). Raw (unclamped) predictions can go
negative at extreme ages; use
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md)
for FTE calculations, which clamps to zero.

## Usage

``` r
urps_fte_predicted_hours(age, sex)
```

## Arguments

- age:

  Numeric or integer vector of ages. Must be non-empty.

- sex:

  Character vector of `"female"` / `"male"` values, recycled against
  `age`. Can be length-1 (applied to all ages) or the same length as
  `age` (one sex per provider row).

## Value

Numeric vector the same length as `max(length(age), length(sex))`
(weekly hours; may be negative at extreme ages).

## See also

[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md),
[`urps_fte_sex_hours_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_sex_hours_params.md)

Other URPS FTE sex:
[`URPS_FTE_REFERENCE_HOURS_PER_WEEK`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md),
[`URPS_FTE_SEX_HOURS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_SEX_HOURS_VERSION.md),
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md),
[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md),
[`urps_fte_sex_hours_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_sex_hours_params.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md),
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md)

## Examples

``` r
urps_fte_predicted_hours(35:75, "female")
#>  [1] 43.000 43.805 44.520 45.145 45.680 46.125 46.480 46.745 46.920 47.005
#> [11] 47.000 46.905 46.720 46.445 46.080 45.625 45.080 44.445 43.720 42.905
#> [21] 42.000 41.005 39.920 38.745 37.480 36.125 34.680 33.145 31.520 29.805
#> [31] 28.000 26.105 24.120 22.045 19.880 17.625 15.280 12.845 10.320  7.705
#> [41]  5.000
urps_fte_predicted_hours(47, "male") # peak: ~55 hrs/week
#> [1] 55
# mixed-sex cohort vector:
urps_fte_predicted_hours(c(45, 55), c("female", "male"))
#> [1] 47.00000 51.07407
```
