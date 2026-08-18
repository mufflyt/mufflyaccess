# Non-contiguous state/territory USPS codes (excluded from CONUS analyses)

Non-contiguous state/territory USPS codes (excluded from CONUS analyses)

## Usage

``` r
NON_CONTIGUOUS_CODES
```

## Format

Character vector of USPS codes.

## Source

Primary: U.S. Census Bureau ANSI (formerly FIPS 5-2) state/territory
codes, <https://www.census.gov/library/reference/code-lists/ansi.html>.
Promoted from isochrones/R/geographic_classification.R.

## See also

[NON_CONTIGUOUS_FIPS](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_FIPS.md)
(the FIPS form),
[CONUS_STATE_ABBR](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_ABBR.md)
(the complement)

Other geography constants:
[`CONUS_STATE_ABBR`](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_ABBR.md),
[`CONUS_STATE_FIPS`](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md),
[`NON_CONTIGUOUS_FIPS`](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_FIPS.md)

## Examples

``` r
NON_CONTIGUOUS_CODES # "HI" "AK" "PR" "GU" "VI" "AS" "MP"
#> [1] "HI" "AK" "PR" "GU" "VI" "AS" "MP"
```
