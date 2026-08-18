# Canonicalize NPI identifiers to 10-digit strings (SSOT)

The single canonical NPI normalizer for the OB/GYN subspecialty
projects. Promoted verbatim from isochrones (`R/join_standards.R`) so
`twostep`, `cliff`, `simulation`, `mysterycall`, and `mysterymaps` stop
re-rolling weaker copies (`sprintf("%.0f")`,
[`as.integer()`](https://rdrr.io/r/base/integer.html),
[`trimws()`](https://rdrr.io/r/base/trimws.html)), which silently
corrupt NPIs via leading-zero loss or 32-bit overflow.

## Usage

``` r
canon_npi(x, verbose = TRUE)
```

## Arguments

- x:

  Atomic vector of raw NPI values (character or numeric).

- verbose:

  Logical; when `TRUE` (default) emit a per-reason summary of rejected
  values via [`message()`](https://rdrr.io/r/base/message.html).

## Value

Character vector the same length as `x`: a 10-digit NPI or
`NA_character_`.

## Details

Strips whitespace/`-`/`.` separators; rejects scientific notation,
embedded letters, non-digit-only values, and values with more than 10
digits; then left-zero-pads to 10 and validates `^[0-9]{10}$`. Rejected
and NA/empty inputs return `NA_character_`.

## Examples

``` r
canon_npi(c("1234567893", "12-3456 7890", "abc", NA), verbose = FALSE)
#> [1] "1234567893" "1234567890" NA           NA          
```
