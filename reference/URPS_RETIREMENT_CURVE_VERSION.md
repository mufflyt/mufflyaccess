# Version of the URPS retirement survival curve model

Semantic version of the logistic survival curve parameter set served by
this package. Bump when parameters or the formula change, so a
downstream projection can record exactly which curve it was built
against.

## Usage

``` r
URPS_RETIREMENT_CURVE_VERSION
```

## Format

Length-1 character string (e.g. `"1.0.0"`).

## See also

[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md),
[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md)

Other URPS retirement curve:
[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md),
[`urps_survival_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_survival_curve.md)

## Examples

``` r
URPS_RETIREMENT_CURVE_VERSION
#> [1] "1.0.0"
```
