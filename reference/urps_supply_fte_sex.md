# Full supply pipeline: certified headcount -\> supply_clinical_fte (sex-stratified)

Composes the three supply-side adjustments in the correct order:

1.  **LFP** (`urps_p_active`): `certified_n → practicing_n`

2.  **FTE weight** (`urps_fte_weight_sex`): hours/40 × pathway clinical
    time × late_factor

3.  **Scale** (`baseline_scale`): anchors FTE to the 2023 baseline
    headcount

Equivalent to:

    cohort <- urps_apply_lfp(cohort)   # adds practicing_n
    urps_effective_fte_sex(
      data.frame(age=cohort$age, sex=cohort$sex,
                 pathway=cohort$pathway, n=cohort$practicing_n),
      scale = baseline_scale, ...)

Use this function when cliff passes certified headcount per cohort cell.
If practicing headcount is already known (e.g. from survey
direct-count), call
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md)
directly.

## Usage

``` r
urps_supply_fte_sex(
  cohort,
  baseline_scale,
  late_from_age = NULL,
  late_factor = 1
)
```

## Arguments

- cohort:

  A `data.frame` with columns `age`, `sex`, `pathway`, and
  `certified_n`. The `n` column (if present) is ignored; `certified_n`
  is used.

- baseline_scale:

  Scale from
  [`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md)
  computed on the 2023 baseline certified cohort. Must be computed ONCE
  and reused across years.

- late_from_age, late_factor:

  Late-career FTE lever — pass values from
  `urps_scenario(id)$late_career_fte_onset_age` and
  `urps_scenario(id)$late_career_fte_factor`. Defaults leave weight
  unchanged.

## Value

Length-1 numeric: `supply_clinical_fte` for this cohort row.

## See also

[`urps_apply_lfp()`](https://mufflyt.github.io/mufflyaccess/reference/urps_apply_lfp.md),
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md),
[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md),
[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md)

Other URPS FTE sex:
[`URPS_FTE_REFERENCE_HOURS_PER_WEEK`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md),
[`URPS_FTE_SEX_HOURS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_SEX_HOURS_VERSION.md),
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md),
[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md),
[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md),
[`urps_fte_sex_hours_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_sex_hours_params.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md)

## Examples

``` r
cohort <- data.frame(
  age = c(45L, 62L, 45L, 62L),
  sex = c("female", "female", "male", "male"),
  pathway = c("ABOG", "ABOG", "ABU", "ABU"),
  certified_n = c(350, 150, 100, 40)
)
scale <- urps_fte_scale_sex(
  cbind(cohort, n = cohort$certified_n *
    urps_p_active(cohort$age, cohort$sex))
)
urps_supply_fte_sex(cohort, scale)
#> [1] 589.4099
```
