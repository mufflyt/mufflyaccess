# Literature-calibrated URPS labor force participation parameters

Logistic regression coefficients (intercept, b_age) predicting the
probability that a board-certified URPS provider is actively practicing
in a given year, conditional on not having permanently retired.
Stratified by sex.

## Usage

``` r
urps_lfp_params()
```

## Value

A `data.frame` with columns `sex`, `intercept`, `b_age`,
`anchor_age_lo`, `anchor_p_lo`, `anchor_age_hi`, `anchor_p_hi`, and
`calibration_status`. Carries attributes `source`, `formula`.

## Details

**Distinction from the retirement model:**
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md)
models the annual probability of *permanent* exit.
[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md)
models the conditional probability of *current* practice given
still-certified — capturing sabbaticals, leaves of absence, and
part-time transitions that don't register as retirements. Both compose
in cliff's recurrence:
`practicing_n = certified_n × urps_p_active(age, sex)`.

**Calibration:** `"calibrated_from_literature"` — derived from two
anchor points per sex (see `anchor_*` columns) from ACOG 2021 and AMA
2022 surveys. Individual ABOG lapse records or a URPS practice survey
would sharpen them.

## See also

[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md),
[`urps_lfp_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_curve.md),
[URPS_LFP_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_LFP_VERSION.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md)

Other URPS LFP:
[`URPS_LFP_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_LFP_VERSION.md),
[`urps_apply_lfp()`](https://mufflyt.github.io/mufflyaccess/reference/urps_apply_lfp.md),
[`urps_lfp_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_curve.md),
[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md)

## Examples

``` r
urps_lfp_params()
#>      sex intercept       b_age anchor_age_lo anchor_p_lo anchor_age_hi
#> 1 female  7.012790 -0.08841729            40        0.97            65
#> 2   male  7.343371 -0.08628877            40        0.98            65
#>   anchor_p_hi         calibration_status
#> 1        0.78 calibrated_from_literature
#> 2        0.85 calibrated_from_literature
attr(urps_lfp_params(), "formula")
#> [1] "logit(P(active)) = intercept + b_age * age;  P = 1 / (1 + exp(-logit))"
```
