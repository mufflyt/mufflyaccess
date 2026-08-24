# Validate a URPS workforce artifact directory (fail loud, semantic)

Path-based contract check used before adopting an isochrones release.
Verifies far more than a checksum: the contract version is supported,
the counts table carries the `measure`/`geography` schema, each measure
stays inside its declared year window, every measure/year/ pathway is
published for **both** geographies, `ABOG_PLUS_ABU` reconciles as
`ABOG + ABU_NET_NEW`, hashes are well formed, the release-contract
canonical cell agrees with the counts table, the CSV SHA-256 matches the
manifest, and – when a parquet reader is available – the served counts
reconstruct from the provider snapshot.

## Usage

``` r
validate_urps_artifact(path)
```

## Arguments

- path:

  Directory holding `urps_counts_by_year.csv` + `urps_manifest.json`
  (and, optionally, `urps_release_contract.json` / the provider
  parquet).

## Value

Invisibly `TRUE`; otherwise stops with the failed check.

## Details

Checks performed, each failing loud with a specific message:

- required files present; contract version valid, supported major, and
  consistent between manifest and release contract;

- the `measure x geography` schema, known measure/geography/pathway
  values, and each measure inside its declared year window;

- no duplicate keys; every `(measure, year)` cell present for **both**
  geographies and all three pathways;

- `ABOG_PLUS_ABU == ABOG + ABU_NET_NEW`; 64-hex `source_sha256`;
  manifest snapshot date consistent with the table;

- release-contract canonical cell agrees with the counts table;

- CSV SHA-256 matches the manifest;

- with a parquet reader, the served counts reconstruct from the provider
  snapshot (subspecialty-cert basis).

## See also

[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md),
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md)

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
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
# the bundled artifact validates:
validate_urps_artifact(system.file("extdata", package = "mufflyaccess"))
```
