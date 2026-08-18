# Safe Division with Zero-Denominator Handling

Performs division with explicit handling of zero denominators to prevent
Inf/NaN propagation and silent failures. Supports multiple legacy
parameter signatures for project-wide compatibility.

## Usage

``` r
safe_divide(
  numerator,
  denominator,
  default = NA_real_,
  zero_threshold = 1e-10,
  on_zero = c("silent", "warning", "error"),
  na_value = NULL
)
```

## Arguments

- numerator:

  `numeric vector`: Dividend. Recycled to match `denominator` length
  when length-1; stops if both are length \> 1 and unequal. Must be
  numeric or logical: character and factor arguments stop rather than
  being coerced, because the `NA` that coercion produced was
  indistinguishable from the `NA` a zero denominator produces.

- denominator:

  `numeric vector`: Divisor. Recycled symmetrically. Elements where
  `abs(denominator) < zero_threshold` or `is.na(denominator)` are
  treated as zero. Same type rule as `numerator`.

- default:

  `numeric scalar`: Value substituted wherever the denominator is
  effectively zero (default: `NA_real_`).

- zero_threshold:

  `numeric scalar`: Absolute tolerance below which `denominator` is
  treated as zero (default: `1e-10`). Pass `0` for exact integer checks.

- on_zero:

  `character(1)`: Action to take on zero denominator. One of "silent"
  (default), "warning", or "error". (Legacy support for
  silent_error_guards.R)

- na_value:

  `numeric scalar`: Alias for `default`. (Legacy support for
  calculate_retirement_cliff_statistics.R)

## Value

`numeric vector` Same length as `denominator` (after recycling).
Non-zero-denominator elements hold the quotient; zero-denominator
elements hold `default`.

## Safe Division Family

This file defines six related functions that all share the same
guarantee: a zero or NA denominator never produces `Inf`, `NaN`, or an
uncaught error — it returns a caller-specified default instead. Choose
the variant that matches the calling context:

- `safe_divide()`:

  The core primitive used inside pipeline computations. Returns
  `NA_real_` by default on a zero denominator so that downstream logic
  can detect and handle missing values explicitly.

- [`safe_divide_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide_manu.md):

  A thin alias of `safe_divide()` with parameter names
  (`num`/`den`/`fallback`) that match the naming conventions used
  throughout `manuscript/R/`. Use this whenever you are converting raw
  counts to millions-scale values inside a manuscript script.

- [`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md):

  Returns a rounded percentage value (e.g., `45.0`) rather than a
  proportion, and `NA_real_` on a zero, `NA` or `NULL` denominator. Use
  this for inline manuscript statistics, where a missing denominator
  must stay visibly missing. This paragraph used to say it returns `0`,
  and recommended it on the grounds that `"0%"` displays better than
  `NA` — that is the behaviour DEN-032 retracted, after `default = 0`
  made Step 4/11 report 0\\ manufactured care deserts that were not in
  the data. The code has returned `NA_real_` since; only this summary
  lagged. Do not restore the old wording without also reading the note
  on
  [`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md)
  below, which keeps `default = 0` and is therefore the one to avoid in
  an analytic table.

- [`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md):

  The standard percentage function for all pipeline metrics and figure
  annotations. Computes `round((part / total) * 100, digits)` and
  returns `default` (0 by default) when `total` is zero.

- [`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md):

  Used for epidemiological rates such as subspecialists per 100K women.
  Multiplies the safe quotient by a `multiplier` argument before
  rounding, and returns `NA_real_` on a zero denominator so that sparse
  census tracts are distinguishable from truly zero-rate tracts.

- [`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md):

  Produces a rounded unitless ratio (e.g., MOE-to-estimate,
  physician-to-population). Returns `NA_real_` on a zero denominator.
  Differs from
  [`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md)
  in that it does not multiply by 100, and from
  [`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md)
  in that it has no `multiplier` argument.

## See also

[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md),
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md),
[`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md)
for rounded percentage/rate/ratio wrappers built on this primitive.

Other safe-arithmetic:
[`safe_divide_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_divide_manu.md),
[`safe_pct_manu()`](https://mufflyt.github.io/mufflyaccess/reference/safe_pct_manu.md),
[`safe_percent()`](https://mufflyt.github.io/mufflyaccess/reference/safe_percent.md),
[`safe_rate()`](https://mufflyt.github.io/mufflyaccess/reference/safe_rate.md),
[`safe_ratio()`](https://mufflyt.github.io/mufflyaccess/reference/safe_ratio.md)

## Examples

``` r
safe_divide(10, 2) # 5
#> [1] 5
safe_divide(1, 0) # NA_real_ (no Inf)
#> [1] NA
safe_divide(1, 0, default = 0) # 0
#> [1] 0
safe_divide(c(10, 20), c(2, 0)) # c(5, NA)  -- vectorised, element-wise guard
#> [1]  5 NA
safe_divide(1, 1e-12) # NA (denominator below zero_threshold)
#> [1] NA
```
