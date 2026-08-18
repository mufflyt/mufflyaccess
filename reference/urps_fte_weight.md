# Per-provider URPS clinical-FTE weight

The canonical headcount-\>FTE weight for one or more providers: age
productivity x pathway clinical time x an optional late-career factor.
Multiply by a headcount and a normalization scale (see
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md))
for a clinical-FTE capacity index.

## Usage

``` r
urps_fte_weight(age, pathway = "ABOG", late_from_age = NULL, late_factor = 1)
```

## Arguments

- age:

  Integer/numeric age(s), clamped to the curve's support.

- pathway:

  `"ABOG"` / `"ABU"` (recycled against `age`); any other value is
  treated as full clinical time (e.g. a pre-combined cohort).
  `"ABOG_PLUS_ABU"` is NOT a per-provider pathway – weight ABOG and ABU
  providers separately and sum, so the combined weight reflects the true
  pathway mix.

- late_from_age:

  If non-`NULL`, ages at/above this get `late_factor` (pass
  `urps_scenario(id)$late_career_fte_onset_age`).

- late_factor:

  Late-career clinical-FTE multiplier (pass
  `urps_scenario(id)$late_career_fte_factor`; default 1 = no reduction).

## Value

Numeric weight(s), same length as `age`.

## See also

[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md),
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md)

Other URPS FTE:
[`URPS_FTE_PATHWAY_CLINICAL_TIME`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_PATHWAY_CLINICAL_TIME.md),
[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md),
[`urps_fte_age_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_age_curve.md),
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md)

## Examples

``` r
urps_fte_weight(c(45, 62), c("ABOG", "ABU"), late_from_age = 60, late_factor = 0.75)
#> [1] 0.988000 0.309225
```
