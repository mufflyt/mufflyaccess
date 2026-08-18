# Entry into the board-certified URPS stock, by year and pathway

Year-over-year additions to the active board-certified URPS stock,
derived from `urps_subspecialty_cert_year` (the column `n_active` is
keyed on). These are **entry into the board-certified URPS stock**, and
are explicitly NOT:

- fellowship graduation year;

- first year of clinical practice;

- net workforce growth (there is no attrition term – see below).

While exits are `not_ascertained` (the current contract) these equal
gross entrants; if a future artifact ascertains exits, this becomes
net-of-exits and callers should switch to a provider-level entry count.
The first year of the series is a **founding bucket**: all entries on or
before that year (the build-up cannot separate pre-window certifications
from that year alone); subsequent years are single-year entries.

## Usage

``` r
urps_entry_counts(measure = "board_certified_active", geography = "national")
```

## Arguments

- measure:

  `"board_certified_active"` (default) or `"roster_snapshot"`.

- geography:

  `"national"` (default) or `"conus"`.

## Value

A `data.frame`: `year`, `measure`, `geography`, `abog_entrants`,
`abu_entrants`, `combined_entrants`, `basis`, `interpretation`,
`first_year_is_founding_bucket`.

## See also

[`urps_entrants()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entrants.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
[`urps_entrants()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entrants.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md),
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
# Entry into the certified stock by year and pathway.
# The first row is the founding bucket (all entries through that year).
head(urps_entry_counts())
#>   year                measure geography abog_entrants abu_entrants
#> 1 2013 board_certified_active  national           471          184
#> 2 2014 board_certified_active  national           166            9
#> 3 2015 board_certified_active  national            87           15
#> 4 2016 board_certified_active  national            26           10
#> 5 2017 board_certified_active  national            30            3
#> 6 2018 board_certified_active  national            34            6
#>   combined_entrants                       basis
#> 1               655 urps_subspecialty_cert_year
#> 2               175 urps_subspecialty_cert_year
#> 3               102 urps_subspecialty_cert_year
#> 4                36 urps_subspecialty_cert_year
#> 5                33 urps_subspecialty_cert_year
#> 6                40 urps_subspecialty_cert_year
#>                                                                                                       interpretation
#> 1 entry into the board-certified URPS stock (NOT fellowship graduation / first clinical year / net workforce growth)
#> 2 entry into the board-certified URPS stock (NOT fellowship graduation / first clinical year / net workforce growth)
#> 3 entry into the board-certified URPS stock (NOT fellowship graduation / first clinical year / net workforce growth)
#> 4 entry into the board-certified URPS stock (NOT fellowship graduation / first clinical year / net workforce growth)
#> 5 entry into the board-certified URPS stock (NOT fellowship graduation / first clinical year / net workforce growth)
#> 6 entry into the board-certified URPS stock (NOT fellowship graduation / first clinical year / net workforce growth)
#>   first_year_is_founding_bucket
#> 1                          TRUE
#> 2                         FALSE
#> 3                         FALSE
#> 4                         FALSE
#> 5                         FALSE
#> 6                         FALSE
```
