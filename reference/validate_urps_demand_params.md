# Validate a URPS demand-model parameter artifact

Fail-loud check that a demand-parameter `data.frame` conforms to
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md)
and is internally consistent with its declared `calibration_status`: the
six service types and their model forms are exactly as specified; every
required column is present; `calibration_scalar > 0`; and the
coefficient/dispersion pattern matches the status – `"not_calibrated"`
requires every beta `NA`, while `"calibrated"` / `"literature_proxy"` /
`"example"` require every beta finite and a positive `nb_theta` on (and
only on) the negative-binomial rows.

## Usage

``` r
validate_urps_demand_params(x)
```

## Arguments

- x:

  A demand-parameter `data.frame` (e.g. from
  [`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md)
  or
  [`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)).

## Value

Invisibly `TRUE` when valid; otherwise an error describing the first
violated rule.

## See also

[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_clinical_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_clinical_fte.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md)

## Examples

``` r
validate_urps_demand_params(urps_demand_params()) # the NA skeleton is valid
```
