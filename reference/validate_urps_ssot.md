# Validate the URPS workforce SSOT (fail loud)

With no `counts`, validates the active artifact end to end via
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md)
and enforces the requested release gates. With a wide `counts`
`data.frame` (as from
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md)),
checks that table's schema, unique + complete 2013-2023 years, 64-hex
hashes, and the `combined_active == abog_active + abu_net_new` identity.

## Usage

``` r
validate_urps_ssot(
  counts = NULL,
  require_external = FALSE,
  require_canonical = FALSE,
  require_contract_version = NULL,
  require_source_git_commit = NULL
)
```

## Arguments

- counts:

  Optional wide counts `data.frame`; `NULL` (default) validates the
  active artifact.

- require_external:

  If `TRUE`, require an external released artifact (not the bundled
  bootstrap).

- require_canonical:

  If `TRUE`, require `canonical_release`.

- require_contract_version:

  Optional exact contract version string to require.

- require_source_git_commit:

  Optional exact source git commit to require.

## Value

Invisibly `TRUE`; otherwise stops with the failed check.

## See also

[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
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
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md)

## Examples

``` r
validate_urps_ssot() # the active artifact
validate_urps_ssot(urps_counts()) # a wide counts table
# release gate (errors on the bundled bootstrap):
try(validate_urps_ssot(require_external = TRUE, require_contract_version = "3.0.0"))
#> Error : [validate] require_external = TRUE but the active artifact is the bundled bootstrap (not a canonical release); call use_urps_artifact('<released dir>') first.
```
