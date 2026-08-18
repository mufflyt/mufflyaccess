# Total-female access-table denominator category label

The `category` value marking the all-female-population row in the access
tables (`filter(category == DENOMINATOR_CATEGORY)`) – the denominator
for every access percentage. The race categories are a DISTINCT
`"total_female_<race>"` prefixed family and are intentionally NOT this
value.

## Usage

``` r
DENOMINATOR_CATEGORY
```

## Format

Character scalar.

## Source

isochrones/R/access_categories.R

## See also

[TOTAL_FEMALE_VAR](https://mufflyt.github.io/mufflyaccess/reference/TOTAL_FEMALE_VAR.md)
(the ACS variable behind this denominator)

Other census denominators:
[`ACS2020_CONUS_FEMALE_POP`](https://mufflyt.github.io/mufflyaccess/reference/ACS2020_CONUS_FEMALE_POP.md),
[`TOTAL_FEMALE_VAR`](https://mufflyt.github.io/mufflyaccess/reference/TOTAL_FEMALE_VAR.md)

## Examples

``` r
DENOMINATOR_CATEGORY # "total_female"
#> [1] "total_female"
# select the denominator rows of a Step-4 access table:
# subset(access_tbl, category == DENOMINATOR_CATEGORY)
```
