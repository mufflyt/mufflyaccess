# Mean completed parity by birth cohort, interpolated across cited anchors

Mean completed parity by birth cohort, interpolated across cited anchors

## Usage

``` r
completed_parity_for_cohort(cohorts, par = NULL)
```

## Arguments

- cohorts:

  Integer birth-cohort years.

- par:

  Optional data frame with `birth_cohort` and `mean_completed_parity`,
  overriding the packaged anchor series.

## Value

Numeric mean completed parity, clamped outside the anchor range.

## See also

Other obstetric exposure:
[`cesarean_rate_for_year()`](https://mufflyt.github.io/mufflyaccess/reference/cesarean_rate_for_year.md),
[`cohort_vaginal_exposure()`](https://mufflyt.github.io/mufflyaccess/reference/cohort_vaginal_exposure.md)

## Examples

``` r
completed_parity_for_cohort(c(1940, 1960, 1980))
#> [1] 2.882353 1.911111 1.946667
```
