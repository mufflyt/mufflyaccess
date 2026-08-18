# Standardize US state values to canonical names or 2-letter codes (SSOT)

The single canonical state-name normalizer for the OB/GYN subspecialty
projects. Promoted from isochrones (`R/utils_standardized.R`) so
consumers stop re-rolling `setNames(state.abb, state.name)` lookups.
Handles the 50 states, DC, and the five territories (PR, GU, VI, AS, MP)
in either direction.

## Usage

``` r
standardize_state_name(x, output = c("name", "abbr"))
```

## Arguments

- x:

  Character vector of raw state values (full names, codes, or
  underscored names, any case).

- output:

  `"name"` (default) for the full name, or `"abbr"` for the 2-letter
  USPS code.

## Value

Character vector: canonical name or code; unmapped values fall back to
title case (for `"name"`) or `NA_character_` (for `"abbr"`).

## Details

The output is byte-identical to the isochrones original; only two
isochrones- specific SIDE EFFECTS were dropped (an unconditional
`[INFO]` print and an audible `beep`), which have no place in a shared
library and do not affect the returned value.

## Examples

``` r
standardize_state_name(c("colorado", "TX", "Puerto Rico"), output = "abbr")
#> [1] "CO" "TX" "PR"
standardize_state_name(c("co", "tx"), output = "name")
#> [1] "Colorado" "Texas"   
```
