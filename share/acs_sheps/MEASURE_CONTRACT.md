# URPS workforce — measurement contract (for ACS / Sheps)

**The measurement contract comes before any headline number.** A count of
urogynecology / reconstructive-pelvic-surgery (URPS) physicians is only
interpretable once the *measure*, *year*, *geography*, and *pathway inclusion* are
specified.

> **1,339 is the 2025 roster snapshot. It is not the 2023 board-certified active
> workforce count (that is 1,332 national / 1,329 CONUS).** The two are separate
> measures, derived for different years and purposes, and must never be presented
> as the same workforce total or used interchangeably.

## A request is incomplete until it specifies

| Field | Values | Default |
|---|---|---|
| `measure` | `board_certified_active`, `roster_snapshot` | `board_certified_active` |
| `year` | `board_certified_active`: 2013–2023 · `roster_snapshot`: 2025 | — |
| `geography` | `national`, `conus` | `national` |
| `include_urology` | `FALSE` (ABOG only), `TRUE` (ABOG + ABU net-new) | `FALSE` |
| `incomplete` | `"error"`, `"na"` | `"error"` |

### Canonical call

```r
mufflyaccess::urps_count(
  year            = 2023,
  measure         = "board_certified_active",
  geography       = "national",
  include_urology = TRUE,
  incomplete      = "error",
  details         = TRUE
)
# $count = 1332L, plus measure/geography/year/pathway/value_status/
# snapshot_date/contract_version/source_git_commit/canonical_release
```

## Measure crosswalk

| Measure | Meaning | Available years | Appropriate use |
|---|---|---|---|
| `roster_snapshot` | Providers present in a dated source roster | Snapshot-specific (2025) | Current-roster description and roster validation |
| `board_certified_active` | Estimated active board-certified workforce in a specified year | 2013–2023 | Longitudinal workforce trends and historical counts |
| Pathway components (`ABOG`, `ABU_NET_NEW`, `ABOG_PLUS_ABU`) | OB/GYN board pathway, net-new urology pathway, and their reconciled sum | Measure-specific window | Pathway composition and reconciliation |
| Geographic dimension (`national`, `conus`) | Same measure, national roster vs. contiguous-US subset | Measure-specific window | Spatial scope selection |

Headline cells (contract v2.1.0):

| measure / geography | ABOG | ABU net-new | combined |
|---|---|---|---|
| board_certified_active / national / 2023 | 1031 | **301** | **1332** |
| board_certified_active / conus / 2023 | 1030 | 299 | **1329** |
| roster_snapshot / national / 2025 | 1031 | 308 | **1339** |
| roster_snapshot / conus / 2025 | 1030 | 306 | 1336 |

The national−CONUS gap is a real 3-provider difference (1 HI ABOG, 1 PR ABU,
1 HI ABU). The roster−active gap (1339 − 1332 = 7) is the 7 ABU net-new
providers first URPS-certified in 2024–2025, correctly **excluded** from the 2023
active count.

## Data dictionary — national longitudinal series (`urps_national_series_v2.1.0.csv`)

| Column | Meaning |
|---|---|
| `year` | Measure year |
| `measure` | `board_certified_active` or `roster_snapshot` |
| `geography` | `national` or `conus` |
| `board_pathway` | `ABOG`, `ABU_NET_NEW`, or `ABOG_PLUS_ABU` |
| `n_active` | Count for that measure/year/geography/pathway |
| `n_ever_certified`, `n_retired` | Certification build-up / retirements (as supplied by isochrones) |
| `snapshot_date` | Source roster snapshot date (2026-07-22) |
| `source_sha256` | Hash of the enriched source rosters |
| `method_version` | Producer method version |
| `artifact_version`, `contract_version` | Release / contract versions (2.1.0) |
| `source_git_commit` | Producing source commit (isochrones) |
| `package_version` | mufflyaccess version that emitted the extract |
| `completeness_status` | `observed` / `unavailable` |

## Data dictionary — state extract (`urps_state_extract_2023_v2.1.0.csv`)

State-level **counts only** — no physician-level rows. mufflyaccess owns the
counts; **population denominators and access measures are owned by twostep /
isochrones** and are left as empty join columns.

| Column | Meaning |
|---|---|
| `state_or_territory` | Two-letter state / territory |
| `geography_is_conus` | Whether the state is in the contiguous US |
| `year`, `measure` | 2023, `board_certified_active` |
| `abog_active`, `abu_net_new_active`, `combined_active` | Active-in-2023 counts by pathway |
| `small_cell_flag` | `TRUE` when `combined_active < 6` (interpret with care) |
| `population_denominator`, `providers_per_100k_women` | **Empty** — supplied downstream (join on state) |
| `artifact_version`, `contract_version`, `source_git_commit` | Provenance |

Active-in-2023 rule (reconstructed independently from the provider snapshot):
`certification_year <= 2023 AND (retirement_year empty OR retirement_year > 2023)`.
The state counts sum to 1,332, matching the national headline.
