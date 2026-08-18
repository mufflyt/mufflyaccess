# Full URPS retirement survival curve as a data.frame

Returns the complete logistic survival curve and annual hazard over a
specified age range as a `data.frame`. Convenience wrapper for cliff to
tabulate or plot the retirement curve for one sex x pathway x scenario
combination.

## Usage

``` r
urps_survival_curve(
  sex,
  pathway,
  retirement_shift_years = 0L,
  age_range = 35:80
)
```

## Arguments

- sex:

  `"female"` or `"male"` (length-1).

- pathway:

  `"ABOG"` or `"ABU"` (length-1).

- retirement_shift_years:

  Finite numeric scalar scenario lever (default `0L`). Pass
  `urps_scenario(id)$retirement_shift_years`.

- age_range:

  Integer or numeric vector of ages (default `35:80`).

## Value

A `data.frame` with columns `age` (integer), `p_still_active` (numeric,
in (0, 1)), and `annual_hazard` (numeric, in `[0, 1]`). One row per
element of `age_range`.

## See also

[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md)

Other URPS retirement curve:
[`URPS_RETIREMENT_CURVE_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_RETIREMENT_CURVE_VERSION.md),
[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md)

## Examples

``` r
head(urps_survival_curve("female", "ABOG"))
#>   age p_still_active annual_hazard
#> 1  35      0.9994472  0.0001222742
#> 2  36      0.9992903  0.0001569785
#> 3  37      0.9990889  0.0002015238
#> 4  38      0.9988305  0.0002586948
#> 5  39      0.9984988  0.0003320603
#> 6  40      0.9980733  0.0004261922
# retire-2-years-earlier scenario, focused age range:
urps_survival_curve("male", "ABOG",
  retirement_shift_years = urps_scenario("retire_2yr_earlier")$retirement_shift_years,
  age_range = 55:75
)
#>    age p_still_active annual_hazard
#> 1   55     0.93991335    0.01329112
#> 2   56     0.92414182    0.01677977
#> 3   57     0.90465054    0.02109123
#> 4   58     0.88079708    0.02636759
#> 5   59     0.85195280    0.03274792
#> 6   60     0.81757448    0.04035238
#> 7   61     0.77729986    0.04926110
#> 8   62     0.73105858    0.05948963
#> 9   63     0.67917870    0.07096542
#> 10  64     0.62245933    0.08351170
#> 11  65     0.56217650    0.09684622
#> 12  66     0.50000000    0.11059961
#> 13  67     0.43782350    0.12435300
#> 14  68     0.37754067    0.13768752
#> 15  69     0.32082130    0.15023380
#> 16  70     0.26894142    0.16170959
#> 17  71     0.22270014    0.17193812
#> 18  72     0.18242552    0.18084683
#> 19  73     0.14804720    0.18845129
#> 20  74     0.11920292    0.19483162
#> 21  75     0.09534946    0.20010799
```
