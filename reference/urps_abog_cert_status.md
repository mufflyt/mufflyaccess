# Validated ABOG certification status for the URPS board-certified cohort

Per-physician (`abog_id`-keyed) current-use ABOG certification status
for the Female Pelvic Medicine & Reconstructive Surgery (URPS/FPMRS)
board-certified cohort, frozen from isochrones'
`validate_abog_refresh_integrity()` audit of the 2026 ABOG re-scrape.

## Usage

``` r
urps_abog_cert_status()
```

## Value

A `data.frame`, one row per URPS-boarded physician, with columns:

- `abog_id` – integer, ABOG's own provider identifier (join key).

- `certStatus` – character, ABOG's raw (coalesced) certification status
  text, unmodified.

- `cert_category_current` – character, the corrected current-use
  classification (see Details).

- `refresh_is_current` – logical, whether this physician's record was
  actually re-scraped in the 2026 refresh (`FALSE` = carried forward
  from the pre-2026 roster).

- `cert_status_is_expired` – logical, whether a time-limited refreshed
  status has an explicit expiration date that has passed.

- `refresh_snapshot_date` – character (ISO date), date of the source
  ABOG re-scrape this classification was computed from.

- `refresh_source_sha256` – character, SHA-256 of the raw re-scrape file
  the classification was computed from.

- `method_version` – character, version tag of the classifying
  validator.

## Details

**Not distributed with this package.** This is a compiled per-physician
roster and mufflyaccess is a public repository, so the data is NOT
shipped in `inst/extdata` – it is resolved from a local, non-repo path
(`~/private-data/mufflyaccess/urps_abog_cert_status.csv` by default;
override with `options(mufflyaccess.urps_abog_cert_status_path=)` or
`MUFFLYACCESS_URPS_ABOG_CERT_STATUS_PATH`). Callers without a local copy
get a clear error, never a silent empty result.

A raw, coalesced certStatus after a refresh merge does not distinguish a
physician who was actually re-scraped in 2026 from one whose old
"Active"-looking status was simply carried forward because the re-scrape
never reached them. `cert_category_current` corrects for this: an
"Active"-looking status is only reported as `"Active"` when
`refresh_is_current` is `TRUE`; otherwise it is downgraded to
`"Unknown (stale active status)"`. Time-limited certifications that have
since lapsed are downgraded to `"Expired"`. Neither `certStatus` (ABOG's
own raw text) nor `cert_category_current` (the corrected classification)
is modeled or estimated – both come straight from the source audit.

**Scope:** URPS/FPMRS board-certified cohort only
(`subspecialty_name == "Female Pelvic Medicine & Reconstructive Surgery"`
in the ABOG roster), matching every other `urps_*` accessor in this
package. GO/MIGS and the full ABOG-wide roster are out of scope here;
see cliff's `data/abog_provider_dataframe_*.csv` for the unfiltered
roster.

**This is not a retirement model.** `cert_category_current` is ABOG's
own certification-status vocabulary (Active / Retired / Deceased /
Certification lapsed / Unknown ...), observed directly from the source,
not a modeled workforce-exit estimate. Modeled retirement is cliff's
responsibility
([`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md)).

## See also

[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md)

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
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a local copy -- not distributed with the package (see Details).
cs <- urps_abog_cert_status()
table(cs$cert_category_current)
# physicians whose "Active"-looking status is NOT confirmed by the 2026 refresh
subset(cs, cert_category_current == "Unknown (stale active status)")
} # }
```
