# Normalization scale anchoring a sex-stratified reference cohort's FTE to a target

Sex-aware counterpart to
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md):
computes the scale factor so that
`urps_effective_fte_sex(reference_counts, scale)` equals
`target_headcount`. Apply once to the 2023 baseline cohort; reuse the
same scale for all projection years so FTE is comparable across time.

## Usage

``` r
urps_fte_scale_sex(
  reference_counts,
  target_headcount = sum(reference_counts$n)
)
```

## Arguments

- reference_counts:

  A `data.frame(age, sex, pathway, n)` — typically the 2023 baseline
  active cohort with sex distribution applied.

- target_headcount:

  The headcount the reference cohort's FTE should equal (default
  `sum(reference_counts$n)`, i.e. FTE(reference) == headcount).

## Value

A length-1 numeric scale for
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md).

## See also

[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md),
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md)

Other URPS FTE sex:
[`URPS_FTE_REFERENCE_HOURS_PER_WEEK`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md),
[`URPS_FTE_SEX_HOURS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_SEX_HOURS_VERSION.md),
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md),
[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md),
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
urps_fte_scale_sex(cs)
#> [1] 0.966861
```
