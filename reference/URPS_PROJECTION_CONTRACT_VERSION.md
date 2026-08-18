# Version of the URPS projection contract

The semantic version of the cliff -\> mufflyaccess projection-table
contract this package validates. Producers stamp it on their output so a
served projection records exactly which contract it conforms to.

## Usage

``` r
URPS_PROJECTION_CONTRACT_VERSION
```

## Format

Length-1 character string (e.g. `"1.0.0"`).

## See also

[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md),
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)

Other URPS projection:
[`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md),
[`urps_gap_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_gap_fte.md),
[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md),
[`validate_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_projection.md)

## Examples

``` r
URPS_PROJECTION_CONTRACT_VERSION
#> [1] "1.1.0"
```
