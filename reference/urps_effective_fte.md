# Effective clinical-FTE of a headcount cohort

Clinical-FTE capacity index for a cohort given as counts by age and
pathway: `scale * sum(n * urps_fte_weight(age, pathway, ...))`. Pass
`scale` from
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md)
so a reference cohort's effective FTE equals its headcount, making
effective FTE additive across pathway / geography slices.

## Usage

``` r
urps_effective_fte(counts, scale = 1, late_from_age = NULL, late_factor = 1)
```

## Arguments

- counts:

  A `data.frame` with columns `age`, `pathway`, `n`.

- scale:

  Normalization scale (default 1 = raw weighted sum).

- late_from_age, late_factor:

  Passed to
  [`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md).

## Value

A length-1 numeric.

## See also

[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md),
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md)

Other URPS FTE:
[`URPS_FTE_PATHWAY_CLINICAL_TIME`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_PATHWAY_CLINICAL_TIME.md),
[`urps_fte_age_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_age_curve.md),
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md),
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md)

## Examples

``` r
cs <- data.frame(age = c(45, 62, 45, 62), pathway = c("ABOG", "ABOG", "ABU", "ABU"), n = c(10, 5, 4, 2))
urps_effective_fte(cs, scale = urps_fte_scale(cs))
#> [1] 21
```
