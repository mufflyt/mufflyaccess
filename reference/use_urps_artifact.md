# Select the URPS workforce artifact mufflyaccess serves

Point the SSOT readers at a released isochrones artifact directory
(`artifacts/workforce/`). This explicit call **fails closed**: the
directory is fully validated
([`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md))
*before* it is adopted, and an invalid artifact is rejected with an
error while the previously active source is left completely unchanged.
`dir = NULL` resets to the bundled bootstrap. Setting the source through
the `mufflyaccess.urps_artifact_dir` option /
`MUFFLYACCESS_URPS_ARTIFACT_DIR` environment variable instead does not
error at read time: an unusable directory warns and falls back to the
bundled bootstrap, revealed by `urps_provenance()$artifact_source` /
`$external_artifact_error`
(`options(mufflyaccess.urps_artifact_strict = TRUE)` makes that fallback
an error).

## Usage

``` r
use_urps_artifact(dir = NULL)
```

## Arguments

- dir:

  Path to an isochrones `artifacts/workforce/` directory, or `NULL`.

## Value

Invisibly the resolved directory (or `"bundled"`).

## See also

[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md)

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
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
if (FALSE) { # \dontrun{
use_urps_artifact("path/to/isochrones/artifacts/workforce") # validated; fails closed
urps_provenance()$artifact_source # "external"
use_urps_artifact(NULL) # back to the bundled bootstrap
} # }
```
