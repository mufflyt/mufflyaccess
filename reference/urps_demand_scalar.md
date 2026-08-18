# Look up the calibration scalar for a service setting

Returns the multiplicative calibration scalar for one setting. Until
calibrated, this is always `1.0`. Fail-loud on unknown settings.

## Usage

``` r
urps_demand_scalar(setting)
```

## Arguments

- setting:

  One of `"office"`, `"outpatient"`, `"home_health"`, `"inpatient"`,
  `"ed"`.

## Value

Length-1 numeric scalar (positive).

## See also

[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
urps_demand_scalar("office") # 1.0 until calibrated
#> [1] 1
urps_demand_scalar("inpatient")
#> [1] 1
```
