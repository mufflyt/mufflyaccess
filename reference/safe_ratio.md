# Safe Ratio Calculation

Rounded unitless ratio (e.g. MOE-to-estimate, physician-to-population)
with a zero/NA-denominator guard. Unlike
[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md)
it does not multiply by 100, and unlike
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md)
it has no `multiplier`.

## Usage

``` r
safe_ratio(numerator, denominator, digits = 2, default = NA_real_)
```

## Arguments

- numerator:

  `numeric`: dividend.

- denominator:

  `numeric`: divisor; zero/NA yields `default`.

- digits:

  `integer`: rounding digits (default 2).

- default:

  `numeric scalar`: value on a zero/NA denominator (default `NA_real_`).

## Value

`numeric` ratio rounded to `digits`.

## See also

[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md),
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md)

Other safe-arithmetic:
[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_divide_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide_manu.md),
[`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md),
[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md),
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md)

## Examples

``` r
safe_ratio(1339, 1031) # 1.30  (with-urology : without-urology URPS)
#> [1] 1.3
safe_ratio(1, 0) # NA_real_
#> [1] NA
```
