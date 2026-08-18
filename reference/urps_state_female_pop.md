# ACS 2016-2020 CONUS female population by state

Returns a data frame of contiguous-US female population by state derived
from ACS 2016-2020 5-year estimates, Table B01001_026. Rows are sorted
by state FIPS code.

## Usage

``` r
urps_state_female_pop()
```

## Source

U.S. Census Bureau, American Community Survey 2016-2020 5-Year
Estimates, Table B01001_026 (total female), contiguous U.S. (48 states +
DC). <https://data.census.gov/table/ACSDT5Y2020.B01001>

## Value

A `data.frame` with 49 rows and four columns:

- state_abbr:

  Character. Two-letter USPS state abbreviation.

- state_fips:

  Character. Two-digit Census FIPS code, zero-padded.

- female_pop:

  Integer. ACS 2016-2020 5-year female population count.

- female_share:

  Double. State share of CONUS female population (sums to 1).

Carries attribute
`source = "ACS 2016-2020 5-year, Table B01001_026, CONUS female population."`.

## See also

Other urps geography:
[`urps_allocate_national()`](https://mufflyt.github.io/mufflyaccess/reference/urps_allocate_national.md),
[`urps_state_alloc_weights()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_alloc_weights.md),
[`urps_state_entrant_shares()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_entrant_shares.md)

## Examples

``` r
df <- urps_state_female_pop()
nrow(df) # 49
#> [1] 49
sum(df$female_pop) # 164690617
#> [1] 164690617
head(df)
#>   state_abbr state_fips female_pop female_share
#> 1         AL         01    2481661  0.015068624
#> 2         AZ         04    3682671  0.022361146
#> 3         AR         05    1503453  0.009128954
#> 4         CA         06   19433752  0.118001574
#> 5         CO         08    2856726  0.017346016
#> 6         CT         09    1813099  0.011009121
```
