# National contiguous-US 2020 ACS female population

The published density denominator behind "1 subspecialist per ~N women"
claims. ACS 2016-2020 5-year, table B01001_026 (total female),
contiguous US (48 states + DC).

## Usage

``` r
ACS2020_CONUS_FEMALE_POP
```

## Format

Integer scalar (persons).

## Source

Primary: U.S. Census Bureau, American Community Survey 2016-2020 5-Year
Estimates, Detailed Table B01001 "Sex by Age", variable B01001_026
(total female), summed over the 48 contiguous states + DC.
<https://data.census.gov/table/ACSDT5Y2020.B01001>. Promoted from
isochrones/R/acs_national_female_pop.R.

## See also

[TOTAL_FEMALE_VAR](https://mufflyt.github.io/mufflyaccess/reference/TOTAL_FEMALE_VAR.md)
(the ACS variable code),
[CONUS_STATE_FIPS](https://mufflyt.github.io/mufflyaccess/reference/CONUS_STATE_FIPS.md)
(the scope)

Other census denominators:
[`DENOMINATOR_CATEGORY`](https://mufflyt.github.io/mufflyaccess/reference/DENOMINATOR_CATEGORY.md),
[`TOTAL_FEMALE_VAR`](https://mufflyt.github.io/mufflyaccess/reference/TOTAL_FEMALE_VAR.md)

## Examples

``` r
as.integer(ACS2020_CONUS_FEMALE_POP) # 164690617
#> [1] 164690617
attr(ACS2020_CONUS_FEMALE_POP, "vintage") # "ACS 2016-2020 5-year"
#> [1] "ACS 2016-2020 5-year"
```
