# National URPS workforce count – the published SSOT accessor

The single-source-of-truth accessor for the national urogynecology /
reconstructive-pelvic-surgery (URPS) workforce count. Consumers call
this and **never hardcode or independently derive a national URPS
count** (see `ARCHITECTURE.md`). A count is only interpretable once its
*measure*, *year*, *geography*, and *pathway inclusion* are fixed, so
all four are explicit arguments.

## Usage

``` r
urps_count(
  year = 2023L,
  measure = "board_certified_active",
  geography = "national",
  include_urology = FALSE,
  incomplete = c("error", "na"),
  details = FALSE
)
```

## Arguments

- year:

  Integer measure year. `board_certified_active` covers 2013-2023;
  `roster_snapshot` is the 2025 snapshot. A year outside a measure's
  window is a hard error.

- measure:

  `"board_certified_active"` (default; the active-in-year cohort) or
  `"roster_snapshot"` (the 2025 roster). Case-insensitive.

- geography:

  `"national"` (default) or `"conus"`. Case-insensitive.

- include_urology:

  Single non-`NA` logical. `FALSE` (default) = ABOG only (`ABOG`
  pathway); `TRUE` = both-pathway ABOG + ABU (`ABOG_PLUS_ABU`).

- incomplete:

  How to handle a published cell that is absent/`NA`: `"error"`
  (default) stops with an explanatory message; `"na"` returns
  `NA_integer_`. A year outside a measure's declared window is always a
  hard error, never a silent `NA`.

- details:

  If `TRUE`, return a labelled list instead of a bare integer so a
  downstream caller never receives a context-free number (see
  **Value**).

## Value

With `details = FALSE` (default), a length-1 integer `n_active` (or
`NA_integer_` when `incomplete = "na"` and the cell is absent). With
`details = TRUE`, a named list:

- count:

  the integer count

- year, measure, geography, include_urology:

  the resolved request

- board_pathway:

  `"ABOG"` or `"ABOG_PLUS_ABU"`

- value_status:

  `"observed"` (ABOG) or `"derived"` (ABOG_PLUS_ABU)

- snapshot_date:

  source roster snapshot `Date`

- contract_version, artifact_version, source_git_commit:

  provenance

- canonical_release:

  `TRUE` only when serving an external release

- artifact_source:

  `"external"` or `"bundled_bootstrap"`

## Details

Under contract v3.0.0 `board_certified_active` is keyed on the URPS
**subspecialty** certification year (training-accurate,
post-fellowship), so a provider whose subspecialty certification
postdates the requested year is not yet counted. The two measures answer
different questions and are **not** interchangeable:

- `board_certified_active` – the estimated active board-certified
  workforce in a given year (2013-2023).

- `roster_snapshot` – the 2025 headcount of the identified roster
  (includes providers whose subspecialty certification postdates 2023).

Validation errors are raised (never silent) for an out-of-window year,
an unknown measure/geography, a non-scalar or `NA` argument, and –
unless `incomplete = "na"` – an absent published cell.

## Estimands (contract v3.0.0)

The published 2023 `board_certified_active` and 2025 `roster_snapshot`
cells:

- national / 2023 active: ABOG 1027 + ABU net-new 279 = **1306**

- conus / 2023 active: ABOG 1026 + ABU net-new 277 = **1303**

- national / 2025 roster: 1031 + 308 = **1339**; conus = 1336

**1339 is the 2025 roster snapshot, not the 2023 active count. 1332 /
1329 are RETIRED v2.1.0 cells** (primary-cert basis) surfaced only by
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md)
/
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md)
and must never be presented as current.

## See also

[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
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
urps_count(2023, "board_certified_active", "national", FALSE) # 1027 (ABOG only)
#> [1] 1027
urps_count(2023, "board_certified_active", "national", TRUE) # 1306 (with urology)
#> [1] 1306
urps_count(2023, "board_certified_active", "conus", TRUE) # 1303
#> [1] 1303
urps_count(2025, "roster_snapshot", "national", TRUE) # 1339 (2025 roster)
#> [1] 1339

# a labelled record for a footnote / caption (never a context-free 1306):
str(urps_count(2023, "board_certified_active", "national", TRUE, details = TRUE))
#> List of 13
#>  $ count            : int 1306
#>  $ year             : int 2023
#>  $ measure          : chr "board_certified_active"
#>  $ geography        : chr "national"
#>  $ include_urology  : logi TRUE
#>  $ board_pathway    : chr "ABOG_PLUS_ABU"
#>  $ value_status     : chr "derived"
#>  $ snapshot_date    : Date[1:1], format: "2026-07-22"
#>  $ contract_version : chr "3.0.0"
#>  $ artifact_version : chr "3.0.0"
#>  $ source_git_commit: chr "74085a9e695eec5350275a29d8655512ad57422b"
#>  $ canonical_release: logi FALSE
#>  $ artifact_source  : chr "bundled_bootstrap"

# out-of-window requests are hard errors (a measure is only valid in its window):
try(urps_count(2025, "board_certified_active")) # error: bca is 2013-2023
#> Error : [urps_count] board_certified_active is defined for 2013-2023; year 2025 is an unsupported year.
try(urps_count(2023, "roster_snapshot")) # error: roster is 2025 only
#> Error : [urps_count] roster_snapshot is the 2025 roster snapshot; year 2023 is not available for that measure.
```
