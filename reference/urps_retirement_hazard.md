# Annual retirement hazard: P(retire at age \| active at age - 1)

The discrete conditional retirement probability at each integer age,
defined as `(S(age-1) - S(age)) / S(age-1)`, clamped to `[0, 1]`. This
is the quantity cliff applies per-cohort in the yearly recurrence:
`exits[age] = cohort_n[age-1] * urps_retirement_hazard(age, sex, pathway, shift)`.
Vectorized over `age`.

## Usage

``` r
urps_retirement_hazard(age, sex, pathway, retirement_shift_years = 0L)
```

## Arguments

- age:

  Numeric or integer vector of ages to evaluate. Must be non-empty.

- sex:

  `"female"` or `"male"` (length-1).

- pathway:

  `"ABOG"` or `"ABU"` (per-individual pathway; length-1).

- retirement_shift_years:

  Finite numeric scalar from the scenario registry
  (`urps_scenario(id)$retirement_shift_years`; default `0L`).

## Value

Numeric vector the same length as `age`, values in `[0, 1]`.

## See also

[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md),
[`urps_survival_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_survival_curve.md)

Other URPS retirement curve:
[`URPS_RETIREMENT_CURVE_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_RETIREMENT_CURVE_VERSION.md),
[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md),
[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md),
[`urps_survival_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_survival_curve.md)

## Examples

``` r
urps_retirement_hazard(55:75, "female", "ABOG")
#>  [1] 0.01677977 0.02109123 0.02636759 0.03274792 0.04035238 0.04926110
#>  [7] 0.05948963 0.07096542 0.08351170 0.09684622 0.11059961 0.12435300
#> [13] 0.13768752 0.15023380 0.16170959 0.17193812 0.18084683 0.18845129
#> [19] 0.19483162 0.20010799 0.20441945
urps_retirement_hazard(68, "male", "ABOG",
  retirement_shift_years = urps_scenario("retire_2yr_later")$retirement_shift_years
)
#> [1] 0.0835117
```
