# P(actively practicing) given age and sex

The logistic labor force participation probability:
`P(active | age, sex) = 1 / (1 + exp(-(intercept + b_age * age)))`.
Captures sabbaticals, leaves of absence, and part-time transitions that
do not appear as permanent retirements in the certification record.
Vectorized over both `age` and `sex`.

## Usage

``` r
urps_p_active(age, sex)
```

## Arguments

- age:

  Numeric or integer vector of ages. Must be non-empty.

- sex:

  Character vector of `"female"` / `"male"` values, recycled against
  `age`.

## Value

Numeric vector in (0, 1) the same length as
`max(length(age), length(sex))`.

## Details

**How cliff uses this:** multiply the certified (not permanently
retired) headcount by `urps_p_active()` to get the practicing count
before applying the FTE weight:

    practicing_n    <- certified_n * urps_p_active(age, sex)
    supply_fte_cell <- practicing_n * urps_fte_weight_sex(age, sex, pathway, ...)

## See also

[`urps_lfp_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_params.md),
[`urps_lfp_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_curve.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_fte_weight_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_fte_weight_sex.md)

Other URPS LFP:
[`URPS_LFP_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_LFP_VERSION.md),
[`urps_apply_lfp()`](https://mufflyt.github.io/mufflyaccess/reference/urps_apply_lfp.md),
[`urps_lfp_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_curve.md),
[`urps_lfp_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_params.md)

## Examples

``` r
urps_p_active(40, "female") # ~0.97
#> [1] 0.97
urps_p_active(65, "male") # ~0.85
#> [1] 0.85
urps_p_active(35:75, "female")
#>  [1] 0.9805103 0.9787468 0.9768277 0.9747396 0.9724687 0.9700000 0.9673173
#>  [8] 0.9644036 0.9612404 0.9578085 0.9540872 0.9500549 0.9456885 0.9409642
#> [15] 0.9358567 0.9303401 0.9243874 0.9179709 0.9110622 0.9036327 0.8956538
#> [22] 0.8870967 0.8779335 0.8681372 0.8576821 0.8465446 0.8347035 0.8221406
#> [29] 0.8088416 0.7947965 0.7800000 0.7644528 0.7481617 0.7311401 0.7134087
#> [36] 0.6949957 0.6759371 0.6562767 0.6360656 0.6153626 0.5942333
# mixed-sex cohort:
urps_p_active(c(45, 50), c("female", "male"))
#> [1] 0.9540872 0.9538642
```
