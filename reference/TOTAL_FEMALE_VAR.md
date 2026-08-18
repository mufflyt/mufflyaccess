# Canonical ACS female-population variable codes

The ACS table variables behind every female-population denominator.
`TOTAL_FEMALE_VAR` is total female from the full B01001 table;
`RACE_FEMALE_VARS` is a named vector of the race-iterated female totals.
**Footgun (why these are pinned here):** the full B01001 table uses the
`_026` total-female cell, but the race-iterated tables (B01001B-I) top
out at `_017` – mixing the two silently double-counts or drops age
bands. Reference these rather than re-typing variable codes.

## Usage

``` r
TOTAL_FEMALE_VAR

RACE_FEMALE_VARS
```

## Format

`TOTAL_FEMALE_VAR` is a character scalar; `RACE_FEMALE_VARS` is a named
character vector (`white_nh`, `hispanic`, `black`, `aian`, `asian`,
`nhpi`).

## Source

Primary: U.S. Census Bureau, American Community Survey Detailed Tables
B01001 "Sex by Age" and the race-iterated B01001B-I,
<https://data.census.gov/table/ACSDT5Y2020.B01001>.

## See also

[ACS2020_CONUS_FEMALE_POP](https://mufflyt.github.io/mufflyaccess/reference/ACS2020_CONUS_FEMALE_POP.md)
(the summed denominator),
[DENOMINATOR_CATEGORY](https://mufflyt.github.io/mufflyaccess/reference/DENOMINATOR_CATEGORY.md)
(the access-table row label)

Other census denominators:
[`ACS2020_CONUS_FEMALE_POP`](https://mufflyt.github.io/mufflyaccess/reference/ACS2020_CONUS_FEMALE_POP.md),
[`DENOMINATOR_CATEGORY`](https://mufflyt.github.io/mufflyaccess/reference/DENOMINATOR_CATEGORY.md)

## Examples

``` r
TOTAL_FEMALE_VAR # "B01001_026" (full table -> _026)
#> [1] "B01001_026"
names(RACE_FEMALE_VARS) # the six race/ethnicity groups
#> [1] "white_nh" "hispanic" "black"    "aian"     "asian"    "nhpi"    
RACE_FEMALE_VARS[["black"]] # "B01001B_017" (race tables -> _017)
#> [1] "B01001B_017"
```
