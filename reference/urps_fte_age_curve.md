# The canonical URPS age-productivity curve

Relative-to-peak clinical productivity by age (the age component of the
clinical-FTE weight), served from the bundled dataset so every consumer
uses one curve.

## Usage

``` r
urps_fte_age_curve()
```

## Value

A `data.frame` with columns `age` (integer) and `rel_to_peak` (numeric).

## See also

[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md)

Other URPS FTE:
[`URPS_FTE_PATHWAY_CLINICAL_TIME`](https://mufflyt.github.io/mufflyaccess/reference/URPS_FTE_PATHWAY_CLINICAL_TIME.md),
[`urps_effective_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte.md),
[`urps_fte_scale()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_scale.md),
[`urps_fte_weight()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight.md)

## Examples

``` r
head(urps_fte_age_curve())
#>   age rel_to_peak
#> 1  35       0.175
#> 2  36       0.246
#> 3  37       0.337
#> 4  38       0.447
#> 5  39       0.572
#> 6  40       0.704
```
