# P(still active) at a given age under the URPS logistic retirement model

The logistic survival function
`S(age; mu, sigma) = 1 / (1 + exp((age - mu) / sigma))`, evaluated at
the effective age after applying the scenario retirement shift.
Vectorized over `age`; `sex` and `pathway` must be length-1 scalars
(call once per sex x pathway cell of your projection cohort).

## Usage

``` r
urps_p_still_active(age, sex, pathway, retirement_shift_years = 0L)
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

Numeric vector the same length as `age`, values in (0, 1).

## Details

**Scenario shift:** `effective_age = age - retirement_shift_years`. Pass
`urps_scenario(id)$retirement_shift_years` directly.

- `retirement_shift_years = -2` (retire earlier):
  `effective_age = age + 2`, so the curve shifts left — lower survival —
  more exits. ✓

- `retirement_shift_years = +2` (retire later):
  `effective_age = age - 2`, higher survival — fewer exits. ✓

## See also

[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_survival_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_survival_curve.md),
[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md),
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md)

Other URPS retirement curve:
[`URPS_RETIREMENT_CURVE_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_RETIREMENT_CURVE_VERSION.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md),
[`urps_survival_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_survival_curve.md)

## Examples

``` r
# at mu (65), female ABOG survival is exactly 0.5
urps_p_still_active(65, "female", "ABOG")
#> [1] 0.5
# full age range, no scenario shift
urps_p_still_active(35:80, "male", "ABU")
#>  [1] 0.99966465 0.99956944 0.99944722 0.99929033 0.99908895 0.99883049
#>  [7] 0.99849882 0.99807327 0.99752738 0.99682732 0.99592986 0.99477987
#> [13] 0.99330715 0.99142251 0.98901306 0.98593637 0.98201379 0.97702263
#> [19] 0.97068777 0.96267311 0.95257413 0.93991335 0.92414182 0.90465054
#> [25] 0.88079708 0.85195280 0.81757448 0.77729986 0.73105858 0.67917870
#> [31] 0.62245933 0.56217650 0.50000000 0.43782350 0.37754067 0.32082130
#> [37] 0.26894142 0.22270014 0.18242552 0.14804720 0.11920292 0.09534946
#> [43] 0.07585818 0.06008665 0.04742587 0.03732689
# retire-2-years-earlier scenario
urps_p_still_active(65, "female", "ABOG",
  retirement_shift_years = urps_scenario("retire_2yr_earlier")$retirement_shift_years
)
#> [1] 0.3775407
```
