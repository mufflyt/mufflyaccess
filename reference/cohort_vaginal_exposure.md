# Cohort vaginal-delivery exposure

Mean vaginal and cesarean deliveries per woman for each birth cohort,
derived from the completed-parity and cesarean-rate series.

## Usage

``` r
cohort_vaginal_exposure(cohorts)
```

## Arguments

- cohorts:

  Integer birth cohorts.

## Value

Data frame: `birth_cohort`, `mean_total_parity`,
`cohort_cesarean_fraction`, `mean_vaginal_deliveries`,
`mean_cesarean_deliveries`.

## Details

Three assumptions, invisible in the returned numbers, are carried by the
derivation. The cohort cesarean fraction is the mean annual rate over
the childbearing window
`OBSTETRIC_CHILDBEAR_AGE_LO:OBSTETRIC_CHILDBEAR_AGE_HI` (ages 20-35),
not the rate in any single year. Parity is then apportioned
vaginal/cesarean by that fraction, which assumes cesarean risk is
independent of birth order; it is not (repeat cesarean is the dominant
indication), so vaginal deliveries are understated for high-parity
cohorts. The interpolators clamp outside the anchor range (`rule = 2`)
rather than extrapolating.

## See also

Other obstetric exposure:
[`cesarean_rate_for_year()`](https://mufflyt.github.io/mufflyaccess/reference/cesarean_rate_for_year.md),
[`completed_parity_for_cohort()`](https://mufflyt.github.io/mufflyaccess/reference/completed_parity_for_cohort.md)

## Examples

``` r
cohort_vaginal_exposure(c(1940, 1970))
#>   birth_cohort mean_total_parity cohort_cesarean_fraction
#> 1         1940             2.882                   0.0584
#> 2         1970             1.967                   0.2334
#>   mean_vaginal_deliveries mean_cesarean_deliveries
#> 1                   2.714                    0.168
#> 2                   1.508                    0.459
```
