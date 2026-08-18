# Contiguous-US state USPS abbreviations (48 states + DC), DERIVED from FIPS

The abbreviation representation of
[CONUS_STATE_FIPS](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md).
Derived through the canonical FIPS-\>USPS crosswalk so the FIPS and
abbreviation forms of "CONUS" can never drift apart. Use this instead of
re-deriving `setdiff(c(state.abb, "DC"), c("AK", "HI"))` inline. NOTE:
plain `c(state.abb, "DC")` (all 50 + DC, includes AK/HI) is a different
set – a state-validation vocabulary, NOT CONUS.

## Usage

``` r
CONUS_STATE_ABBR
```

## Format

Character vector of 49 USPS codes.

## Source

Derived from
[CONUS_STATE_FIPS](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md)
via the U.S. Census Bureau ANSI/FIPS crosswalk,
<https://www.census.gov/library/reference/code-lists/ansi.html>.

## See also

[CONUS_STATE_FIPS](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md)
(the FIPS form it is derived from),
[NON_CONTIGUOUS_CODES](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_CODES.md)

Other geography constants:
[`CONUS_STATE_FIPS`](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md),
[`NON_CONTIGUOUS_CODES`](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_CODES.md),
[`NON_CONTIGUOUS_FIPS`](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_FIPS.md)

## Examples

``` r
length(CONUS_STATE_ABBR) # 49
#> [1] 49
any(c("AK", "HI") %in% CONUS_STATE_ABBR) # FALSE (excluded by construction)
#> [1] FALSE
```
