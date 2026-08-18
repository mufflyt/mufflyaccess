# Pathway clinical-time fractions for the URPS clinical-FTE weighting

Fraction of clinical time an active urogynecologist spends in
urogynecology, by board pathway. ABOG-pathway physicians are treated as
full clinical time in urogynecology; ABU (urology) pathway physicians
spend part of their clinical time in general urology. This is the single
canonical constant consumers weight headcount by; it must not be
redefined per repository.

## Usage

``` r
URPS_FTE_PATHWAY_CLINICAL_TIME
```

## Format

Named numeric vector: `ABOG = 1.00`, `ABU = 0.70`.

## See also

[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md)

Other URPS FTE:
[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md),
[`urps_fte_age_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_age_curve.md),
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md),
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md)

## Examples

``` r
URPS_FTE_PATHWAY_CLINICAL_TIME[["ABU"]]
#> [1] 0.7
```
