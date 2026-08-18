# Non-contiguous state/territory FIPS codes (excluded from CONUS analyses)

Non-contiguous state/territory FIPS codes (excluded from CONUS analyses)

## Usage

``` r
NON_CONTIGUOUS_FIPS
```

## Format

Character vector of 2-digit FIPS codes.

## Source

Primary: U.S. Census Bureau ANSI (formerly FIPS 5-2) state/territory
codes, <https://www.census.gov/library/reference/code-lists/ansi.html>.
Promoted from isochrones/R/geographic_classification.R.

## See also

[NON_CONTIGUOUS_CODES](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_CODES.md)
(the USPS form),
[CONUS_STATE_FIPS](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md)
(the complement)

Other geography constants:
[`CONUS_STATE_ABBR`](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_ABBR.md),
[`CONUS_STATE_FIPS`](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md),
[`NON_CONTIGUOUS_CODES`](https://mufflyt.github.io/mufflyaccess/reference/NON_CONTIGUOUS_CODES.md)

## Examples

``` r
NON_CONTIGUOUS_FIPS # "02" (AK) "15" (HI) "60" ... territories
#> [1] "02" "15" "60" "66" "69" "72" "78"
# drop non-contiguous rows from a state-FIPS-keyed table:
# subset(tbl, !state_fips %in% NON_CONTIGUOUS_FIPS)
```
