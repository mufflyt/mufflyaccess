# Compute gap_fte from supply and demand clinical FTE

Closes the supply/demand/gap triangle:
`gap_fte = demand_clinical_fte - supply_clinical_fte`. Positive =
shortage (demand exceeds supply); negative = surplus. Returns `NA_real_`
if either argument is `NA` (i.e., when the demand model is not yet
calibrated). This is the value that goes in the `gap_fte` column of the
projection contract table.

## Usage

``` r
urps_gap_fte(supply_clinical_fte, demand_clinical_fte)
```

## Arguments

- supply_clinical_fte:

  Length-1 numeric from
  [`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md)
  (or `NA`).

- demand_clinical_fte:

  Length-1 numeric from
  [`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md)
  (or `NA`).

## Value

Length-1 numeric `gap_fte = demand - supply`, or `NA_real_` if either
input is `NA`.

## Details

**Typical cliff usage (per projection row):**

    supply_fte <- mufflyaccess::urps_supply_fte_sex(cohort, baseline_scale, ...)
    demand_fte <- mufflyaccess::urps_demand_fte(population, visits_per_fte,
                    scenario_id = scenario_id)
    gap_fte    <- mufflyaccess::urps_gap_fte(supply_fte, demand_fte)

All three values go directly into the projection contract columns
`supply_clinical_fte`, `demand_clinical_fte`, and `gap_fte`.
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)
enforces the identity when all three are non-NA.

## See also

[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)

Other URPS projection:
[`URPS_PROJECTION_CONTRACT_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_PROJECTION_CONTRACT_VERSION.md),
[`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md),
[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md),
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)

## Examples

``` r
urps_gap_fte(supply_clinical_fte = 1200, demand_clinical_fte = 1450) # +250 shortage
#> [1] 250
urps_gap_fte(supply_clinical_fte = 1400, demand_clinical_fte = 1200) # -200 surplus
#> [1] -200
urps_gap_fte(supply_clinical_fte = 1200, demand_clinical_fte = NA_real_) # NA
#> [1] NA
```
