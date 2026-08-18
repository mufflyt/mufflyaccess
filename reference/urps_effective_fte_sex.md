# Effective clinical FTE of a sex-stratified headcount cohort

Sex-aware counterpart to
[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md):
computes `scale * sum(n * urps_fte_weight_sex(age, sex, pathway, ...))`
for a cohort data.frame that carries per-row sex. Use
[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md)
to anchor the reference cohort's FTE to its headcount before comparing
across years or geographies.

## Usage

``` r
urps_effective_fte_sex(
  counts,
  scale = 1,
  late_from_age = NULL,
  late_factor = 1
)
```

## Arguments

- counts:

  A `data.frame` with columns `age`, `sex`, `pathway`, and `n`.
  Mixed-sex rows are handled natively (no pre-splitting required).

- scale:

  Normalization scale from
  [`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md)
  (default `1` = raw hours/40 weighted sum).

- late_from_age, late_factor:

  Passed to
  [`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md).

## Value

A length-1 numeric (clinical FTE in 40-hrs/wk units after scaling).

## See also

[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md),
[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md)

Other URPS FTE sex:
[`URPS_FTE_REFERENCE_HOURS_PER_WEEK`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md),
[`URPS_FTE_SEX_HOURS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_SEX_HOURS_VERSION.md),
[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md),
[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md),
[`urps_fte_sex_hours_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_sex_hours_params.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md),
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md)

## Examples

``` r
cs <- data.frame(
  age     = c(45L, 62L, 45L, 62L),
  sex     = c("female", "female", "male", "male"),
  pathway = c("ABOG", "ABOG", "ABU", "ABU"),
  n       = c(350, 150, 100, 40)
)
urps_effective_fte_sex(cs, scale = urps_fte_scale_sex(cs))
#> [1] 640
```
