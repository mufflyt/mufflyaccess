# URPS contract lineage (which cells are current vs retired)

A machine-readable lineage of the 2023 board_certified_active
national/CONUS cells across contract versions, built from the served
artifact: the **current** headline (from the manifest) and any
**retired** cells the producer recorded (`retired_cells`). Consumers use
this to detect a value that was canonical under an old contract but must
never be presented as current (e.g. v2.1.0's 1332/1329 after v3.0.0).

## Usage

``` r
urps_lineage()
```

## Value

A `data.frame`, current row first, with columns:

- contract_version:

  e.g. `"3.0.0"` (current) / `"2.1.0"` (retired)

- national_active, conus_active:

  the 2023 board_certified_active cells

- status:

  `"current"` or `"retired"`

- basis:

  the certification basis for that estimate

## Details

The `current` row comes from the served manifest's headline counts; the
`retired` row(s) come from its `retired_cells` block. `basis` names the
certification basis (e.g. URPS subspecialty cert vs primary board cert)
that distinguishes the estimates. A consumer can screen a candidate
value against the `retired` rows (or
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md))
to refuse presenting a stale count as current.

## See also

[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
[`urps_entrants()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entrants.md),
[`urps_entry_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entry_counts.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md),
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
urps_lineage()
#>   contract_version national_active conus_active  status
#> 1            3.0.0            1306         1303 current
#> 2            2.1.0            1332         1329 retired
#>                         basis
#> 1 URPS subspecialty cert year
#> 2     primary board cert year
```
