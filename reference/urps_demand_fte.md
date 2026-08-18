# Scenario-aware demand FTE: registry lookup + clinical FTE in one call

The demand-side counterpart to
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md).
Looks up the demand lever bundle for a registered scenario via
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
then calls
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md)
– so cliff passes a `scenario_id` string rather than four raw lever
values:

    # Supply side (cliff already does this):
    supply_fte <- mufflyaccess::urps_supply_fte_sex(cohort, baseline_scale,
                    late_from_age = sc$late_career_fte_onset_age,
                    late_factor   = sc$late_career_fte_factor)

    # Demand side (new -- call this once per projection row):
    demand_fte <- mufflyaccess::urps_demand_fte(population, visits_per_fte,
                    scenario_id = scenario_id)

    # Gap (close the triangle):
    gap_fte <- mufflyaccess::urps_gap_fte(supply_fte, demand_fte)

Returns `NA_real_` for any scenario while
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)
is the uncalibrated skeleton, and a real `demand_clinical_fte` once a
fitted artifact is active (`calibration_status != "not_calibrated"`; see
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md)).
Cliff can call this unconditionally – the `NA` propagates to `gap_fte`
and the contract validator allows `NA` in optional columns, and it
simply stops being `NA` after activation.

## Usage

``` r
urps_demand_fte(population, visits_per_fte, scenario_id = "baseline")
```

## Arguments

- population:

  A `data.frame` – see
  [`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md).

- visits_per_fte:

  Annual URPS visits per FTE provider. See
  [`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md).

- scenario_id:

  A registered scenario id (default `"baseline"`). The four demand
  levers are resolved from the registry; passing raw lever values is not
  required.

## Value

Length-1 numeric `demand_clinical_fte`, or `NA_real_` until calibrated.

## See also

[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md),
[`urps_gap_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_gap_fte.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
pop <- data.frame(age = 50, sex = "female", n = 10000)
urps_demand_fte(pop, visits_per_fte = 2000) # NA
#> [1] NA
urps_demand_fte(pop, visits_per_fte = 2000, scenario_id = "baseline") # NA
#> [1] NA
urps_demand_fte(pop, 2000, scenario_id = "demand_managed_care_increase") # NA
#> [1] NA
```
