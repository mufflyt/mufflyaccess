# Normalization scale anchoring a reference cohort's effective FTE to a target

Normalization scale anchoring a reference cohort's effective FTE to a
target

## Usage

``` r
urps_fte_scale(reference_counts, target_headcount = sum(reference_counts$n))
```

## Arguments

- reference_counts:

  A `data.frame(age, pathway, n)` (e.g. the baseline-year combined
  national active cohort).

- target_headcount:

  The headcount the reference cohort's effective FTE should equal
  (default `sum(reference_counts$n)`, i.e. FTE(reference) == headcount).

## Value

A length-1 numeric scale for
[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md).

## See also

[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md)

Other URPS FTE:
[`URPS_FTE_PATHWAY_CLINICAL_TIME`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_PATHWAY_CLINICAL_TIME.md),
[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md),
[`urps_fte_age_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_age_curve.md),
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md)

## Examples

``` r
cs <- data.frame(age = c(45, 62), pathway = c("ABOG", "ABU"), n = c(10, 4))
urps_fte_scale(cs)
#> [1] 1.214308
```
