# The URPS projection-table contract schema

The column specification a cliff-produced projection table must satisfy:
the canonical long-table columns, their types, whether each is optional,
and what it means. A producer builds to this;
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)
enforces it.

## Usage

``` r
urps_projection_schema()
```

## Value

A `data.frame` with columns `column`, `type`, `optional`, `description`
(one row per contract column, in canonical order).

## See also

[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md),
[`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md),
[URPS_PROJECTION_CONTRACT_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_PROJECTION_CONTRACT_VERSION.md)

Other URPS projection:
[`URPS_PROJECTION_CONTRACT_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_PROJECTION_CONTRACT_VERSION.md),
[`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md),
[`urps_gap_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_gap_fte.md),
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)

## Examples

``` r
urps_projection_schema()
#>                   column      type optional
#> 1                   year   integer    FALSE
#> 2            scenario_id character    FALSE
#> 3              specialty character    FALSE
#> 4  certification_pathway character    FALSE
#> 5         geography_type character    FALSE
#> 6           geography_id character    FALSE
#> 7       supply_headcount    double    FALSE
#> 8    supply_clinical_fte    double     TRUE
#> 9               lower_95    double     TRUE
#> 10              upper_95    double     TRUE
#> 11              entrants    double     TRUE
#> 12                 exits    double     TRUE
#> 13            net_change    double     TRUE
#> 14   demand_clinical_fte    double     TRUE
#> 15               gap_fte    double     TRUE
#>                                                                                                                                    description
#> 1                                                                                                                              projection year
#> 2                                                                                         scenario id (must be registered in urps_scenarios())
#> 3                                                                                                             subspecialty label (e.g. "URPS")
#> 4                                                                       ABOG, ABU_NET_NEW, or ABOG_PLUS_ABU (the count-contract pathway vocab)
#> 5                                                                                       national or conus (the count-contract geography vocab)
#> 6                                                                      geography identifier within geography_type (e.g. "US", "CONUS", a FIPS)
#> 7                                                                                                  projected supply headcount (point estimate)
#> 8                                                             projected clinical FTE (NA until the age-specific FTE model exists; see CHARTER)
#> 9                                                                                    lower 95% bound on supply_headcount (NA if deterministic)
#> 10                                                                                   upper 95% bound on supply_headcount (NA if deterministic)
#> 11                                                                                                     entrants into the stock during the year
#> 12                                                                                                        exits from the stock during the year
#> 13                                                                       net change in the stock during the year (defined as entrants - exits)
#> 14                                     projected demand in clinical FTE units (NA until demand equations calibrated; see urps_demand_params())
#> 15 gap_fte = demand_clinical_fte - supply_clinical_fte; negative = surplus, positive = shortage (NA unless both demand and supply FTE present)
```
