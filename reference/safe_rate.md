# Safe Rate Calculation (per N)

Epidemiological rate `(events / exposure) * multiplier`, rounded, with a
zero/NA-exposure guard. Returns `NA_real_` (not 0) so sparse tracts are
distinguishable from true zero-rate tracts.

## Usage

``` r
safe_rate(events, exposure, multiplier = 1, digits = 1, default = NA_real_)
```

## Arguments

- events:

  `numeric`: event count (numerator).

- exposure:

  `numeric`: population at risk (denominator); zero/NA yields `default`.

- multiplier:

  `numeric scalar`: rate base, e.g. `1e5` for per-100,000 (default 1).

- digits:

  `integer`: rounding digits (default 1).

- default:

  `numeric scalar`: value on a zero/NA exposure (default `NA_real_`).

## Value

`numeric` rate per `multiplier`, rounded to `digits`.

## See also

[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md)

Other safe-arithmetic:
[`safe_divide()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide.md),
[`safe_divide_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide_manu.md),
[`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md),
[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md),
[`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md)

## Examples

``` r
safe_rate(890, 164690617, multiplier = 1e5) # ~0.5 gyn-onc per 100,000 women
#> [1] 0.5
safe_rate(5, 0, multiplier = 1e5) # NA_real_
#> [1] NA
```
