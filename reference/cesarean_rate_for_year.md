# US total-cesarean rate, interpolated across cited anchor years

US total-cesarean rate, interpolated across cited anchor years

## Usage

``` r
cesarean_rate_for_year(years, ces = NULL)
```

## Arguments

- years:

  Integer calendar years.

- ces:

  Optional data frame with `year` and `cesarean_rate`, overriding the
  packaged anchor series. Present so the interpolation can be tested
  against a known series and so a caller can substitute a revised one
  without editing the package.

## Value

Numeric cesarean fraction per year, clamped at the anchor range ends.

## See also

Other obstetric exposure:
[`cohort_vaginal_exposure()`](https://mufflyt.github.io/mufflyaccess/reference/cohort_vaginal_exposure.md),
[`completed_parity_for_cohort()`](https://mufflyt.github.io/mufflyaccess/reference/completed_parity_for_cohort.md)

## Examples

``` r
cesarean_rate_for_year(c(1990, 2005, 2020))
#> [1] 0.2220000 0.2973333 0.3216667
```
