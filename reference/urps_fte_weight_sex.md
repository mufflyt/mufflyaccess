# Per-provider URPS FTE weight (sex-stratified hours model)

Sex-stratified upgrade to
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md),
following the IHS Markit HWMM Exhibits 14-15 OLS hours-worked approach.
The weight is:

`max(predicted_hours(age, sex), 0) / 40`
`* URPS_FTE_PATHWAY_CLINICAL_TIME[pathway]` `* late_career_factor`

40 hrs/week = 1.0 FTE
([URPS_FTE_REFERENCE_HOURS_PER_WEEK](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md)).
A subspecialist at career peak works \> 1.0 FTE; a late-career provider
with reduced hours may be \< 1.0 FTE.

## Usage

``` r
urps_fte_weight_sex(
  age,
  sex,
  pathway = "ABOG",
  late_from_age = NULL,
  late_factor = 1
)
```

## Arguments

- age:

  Numeric or integer vector of ages.

- sex:

  `"female"` or `"male"` (length-1, recycled against `age`).

- pathway:

  `"ABOG"` or `"ABU"` (recycled against `age`).

- late_from_age:

  If non-`NULL`, ages at or above this receive `late_factor` (pass
  `urps_scenario(id)$late_career_fte_onset_age`).

- late_factor:

  Late-career FTE multiplier (pass
  `urps_scenario(id)$late_career_fte_factor`; default `1` = no
  reduction).

## Value

Numeric weight(s) the same length as `age`. Values \> 1 indicate
above-reference hours; values in (0, 1) indicate below-reference hours
or reduced specialty time.

## Details

Use this function when cliff's provider cohort carries per-provider (or
per-cell) sex data. Use
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md)
when sex data are unavailable, as that function does not require sex.

The `pathway_clinical_time` factor
([URPS_FTE_PATHWAY_CLINICAL_TIME](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_PATHWAY_CLINICAL_TIME.md))
is applied after the hours-to-FTE conversion, capturing the
specialty-time split (ABOG = 1.0 full URPS time; ABU = 0.7 mixed
urology/GYN) independently of the age-sex productivity model.

## See also

[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md),
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md),
[URPS_FTE_PATHWAY_CLINICAL_TIME](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_PATHWAY_CLINICAL_TIME.md),
[URPS_FTE_REFERENCE_HOURS_PER_WEEK](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md)

Other URPS FTE sex:
[`URPS_FTE_REFERENCE_HOURS_PER_WEEK`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_REFERENCE_HOURS_PER_WEEK.md),
[`URPS_FTE_SEX_HOURS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_SEX_HOURS_VERSION.md),
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md),
[`urps_fte_predicted_hours()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_predicted_hours.md),
[`urps_fte_scale_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale_sex.md),
[`urps_fte_sex_hours_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_sex_hours_params.md),
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md)

## Examples

``` r
# Peak male ABOG: ~55 hrs / 40 * 1.0 = 1.375 FTE
urps_fte_weight_sex(47, "male", "ABOG")
#> [1] 1.375
# Peak female ABU: ~47 hrs / 40 * 0.7 = 0.823 FTE
urps_fte_weight_sex(45, "female", "ABU")
#> [1] 0.8225
# Late-career scenario from the registry:
sc <- urps_scenario("lower_late_career_fte")
urps_fte_weight_sex(62, "female", "ABOG",
  late_from_age = sc$late_career_fte_onset_age,
  late_factor   = sc$late_career_fte_factor
)
#> [1] 0.6214688
```
