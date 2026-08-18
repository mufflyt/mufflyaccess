# Manuscript Alias: Safe Division

Thin alias of
[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md)
using the `num`/`den`/`fallback` argument names used across
`manuscript/R/`.

## Usage

``` r
safe_divide_manu(num, den, fallback = NA_real_)
```

## Arguments

- num:

  `numeric`: dividend.

- den:

  `numeric`: divisor; zero/NA yields `fallback`.

- fallback:

  `numeric scalar`: value returned on a zero/NA denominator (default
  `NA_real_`).

## Value

`numeric` quotient, or `fallback` where `den` is zero/NA.

## See also

[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md)

Other safe-arithmetic:
[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md),
[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md),
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md),
[`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md)

## Examples

``` r
safe_divide_manu(10, 5) # 2
#> [1] 2
safe_divide_manu(10, 0, fallback = 0) # 0
#> [1] 0
```
