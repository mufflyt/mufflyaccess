# Contiguous-US state FIPS codes (48 states + DC)

Contiguous-US state FIPS codes (48 states + DC)

## Usage

``` r
CONUS_STATE_FIPS
```

## Format

Character vector of 49 two-digit FIPS codes.

## Source

Primary: U.S. Census Bureau ANSI (formerly FIPS 5-2) state codes,
<https://www.census.gov/library/reference/code-lists/ansi.html>.
Promoted from isochrones/R/geographic_classification.R.

## See also

[CONUS_STATE_ABBR](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_ABBR.md)
(the derived USPS form),
[NON_CONTIGUOUS_FIPS](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_FIPS.md)

Other geography constants:
[`CONUS_STATE_ABBR`](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_ABBR.md),
[`NON_CONTIGUOUS_CODES`](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_CODES.md),
[`NON_CONTIGUOUS_FIPS`](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_FIPS.md)

## Examples

``` r
length(CONUS_STATE_FIPS) # 49 (48 states + DC)
#> [1] 49
"02" %in% CONUS_STATE_FIPS # FALSE (Alaska is non-contiguous)
#> [1] FALSE
```
