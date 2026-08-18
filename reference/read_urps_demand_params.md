# Read a fitted URPS demand-model parameter artifact

Read a demand-parameter CSV produced by the calibration pipeline
(`analysis/urps_demand/fit_urps_demand.R`), coerce the beta / scalar
columns to double, and validate it against
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md).
The returned frame is a drop-in for
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)
– same columns, but with real coefficients and
`calibration_status != "not_calibrated"`.

## Usage

``` r
read_urps_demand_params(path, validate = TRUE)
```

## Arguments

- path:

  Path to the parameter CSV.

- validate:

  Validate before returning (default `TRUE`). Leave `TRUE` unless you
  are deliberately inspecting a malformed artifact.

## Value

A demand-parameter `data.frame` carrying a `calibration_status`
attribute for a quick top-level check.

## See also

[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
ex <- system.file("extdata", "urps_demand_params_example.csv",
  package = "mufflyaccess"
)
if (nzchar(ex)) {
  p <- read_urps_demand_params(ex)
  attr(p, "calibration_status")
}
#> [1] "example"
```
