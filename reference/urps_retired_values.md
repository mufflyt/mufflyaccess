# Values retired from an earlier URPS contract (never present as current)

A flat integer vector of counts that were canonical under a prior
contract and must **not** be presented as current. Use it as a guard in
downstream code and manuscripts (e.g. fail a build if a figure caption
contains one of these as "the 2023 count").

## Usage

``` r
urps_retired_values()
```

## Value

An integer vector of retired national/CONUS 2023 active counts (e.g.
v2.1.0's 1332 / 1329), or `integer(0)` if the artifact records none.

## See also

[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_abog_cert_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_abog_cert_status.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
[`urps_entrants()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entrants.md),
[`urps_entry_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entry_counts.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
urps_retired_values()
#> [1] 1332 1329
# a consumer-side guard:
stopifnot(!urps_count(2023, "board_certified_active", "national", TRUE) %in%
  urps_retired_values())
```
