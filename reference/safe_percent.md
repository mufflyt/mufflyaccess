# Safe Percentage Calculation

`round((part / total) * 100, digits)` with a zero/NA-total guard; the
standard percentage helper for pipeline metrics and figure annotations.

## Usage

``` r
safe_percent(part, total, digits = 1, default = 0)
```

## Arguments

- part:

  `numeric`: numerator (the subset count).

- total:

  `numeric`: denominator (the whole); zero/NA yields `default`.

- digits:

  `integer`: rounding digits (default 1).

- default:

  `numeric scalar`: value returned on a zero/NA total (default 0, i.e.
  "0%"). Use
  [`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md)
  when `NA` is the safer display value.

## Value

`numeric` percentage in `[0, 100]` rounded to `digits`.

## See also

[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md)

Other safe-arithmetic:
[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_divide_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide_manu.md),
[`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md),
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md),
[`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md)

## Examples

``` r
safe_percent(45, 90) # 50
#> [1] 50
safe_percent(1, 3, digits = 2) # 33.33
#> [1] 33.33
safe_percent(1, 0) # 0 (default)
#> [1] 0
```
