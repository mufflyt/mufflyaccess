# Manuscript Alias: Safe Percentage

Returns NA_real\_ when the denominator is 0, NA, or NULL. This matches
the canonical semantics in manuscript/R/00_manuscript_utils.R. The
previous default = 0 caused Step 4/11 to report 0% access when the
denominator was missing, creating phantom care-desert artifacts
(DEN-032).

## Usage

``` r
safe_pct_manu(num, den, digits = 1)
```

## Arguments

- num:

  `numeric`: part (numerator).

- den:

  `numeric`: whole (denominator); zero/NA/NULL yields `NA_real_`.

- digits:

  `integer`: rounding digits for the percentage (default 1).

## Value

`numeric` percentage rounded to `digits`, or `NA_real_` when `den` is
zero/NA/NULL.

## See also

[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md)
(the non-NA-defaulting variant)

Other safe-arithmetic:
[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_divide_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide_manu.md),
[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md),
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md),
[`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md)

## Examples

``` r
safe_pct_manu(45, 90) # 50
#> [1] 50
safe_pct_manu(1, 0) # NA_real_ (not 0 -- avoids phantom 0% artifacts)
#> [1] NA
```
