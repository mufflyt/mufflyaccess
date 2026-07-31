#' mufflyaccess: canonical access, census-denominator, and geography constants (SSOT)
#'
#' @description
#' Single source of truth for the constants and pure statistics shared across the
#' OB/GYN subspecialty geographic-access projects (isochrones, twostep, cliff).
#' Every value carries provenance and fail-loud validation that runs at package
#' load, so the repositories cannot silently disagree about the numbers behind a
#' published statistic.
#'
#' @section Reference by domain:
#' * **Access bands & thresholds** — [PRIMARY_ACCESS_BAND_MIN],
#'   [PRIMARY_ACCESS_BAND_SEC], [CANONICAL_BANDS], [DENOMINATOR_CATEGORY],
#'   [TRACT_REACHED_COVERAGE_PCT], [get_primary_access_band()],
#'   [get_canonical_bands()]
#' * **Census denominators** — [ACS2020_CONUS_FEMALE_POP], [TOTAL_FEMALE_VAR],
#'   [RACE_FEMALE_VARS]
#' * **Geography** — [CONUS_STATE_FIPS], [CONUS_STATE_ABBR], [NON_CONTIGUOUS_FIPS],
#'   [NON_CONTIGUOUS_CODES]
#' * **Margins of error** — [ACS_MOE_Z90], [CI_Z95], [MOE90_TO_CI95_FACTOR]
#' * **Rurality (RUCA)** — [RUCA_NONMETRO_MIN], [rurality_from_ruca()]
#' * **PFD prevalence** — [WU2014_PFD_PREVALENCE], [pfd_prevalence()],
#'   [pfd_prevalence_acs_bands()]
#' * **URPS workforce SSOT** — [urps_count()], [urps_counts()],
#'   [urps_counts_long()], [urps_provenance()], [urps_lineage()],
#'   [urps_retired_values()], [use_urps_artifact()], [validate_urps_artifact()],
#'   [validate_urps_ssot()], [compare_urps_artifacts()]; the deprecated
#'   [URPS_COUNT_ABOG_ONLY_2025] / [URPS_COUNT_ABOG_PLUS_ABU_2025] constants
#' * **URPS scenario dictionary** — [urps_scenarios()], [urps_scenario()],
#'   [urps_scenario_ids()], [is_urps_scenario()], [validate_urps_scenarios()],
#'   [URPS_SCENARIO_REGISTRY_VERSION]
#' * **Accessibility statistics** — [weighted_mean_all()], [zero_access_share()],
#'   [mc_weighted_ci()], [annual_trend()], [tract_vintage_of()], [acs_year_of()]
#' * **Safe division** — [safe_divide()] and its family
#'
#' @section The URPS workforce SSOT:
#' isochrones builds and hashes the provider roster; mufflyaccess reads, validates,
#' and serves it; consumers call [urps_count()] and never derive a national count
#' themselves. The served contract is v3.0.0: the canonical 2023 estimand is
#' `board_certified_active / national` = **1306** (CONUS 1303), **1339** is the
#' 2025 `roster_snapshot`, and the retired v2.1.0 cells (1332 / 1329) are surfaced
#' only via [urps_lineage()] / [urps_retired_values()]. See `ARCHITECTURE.md`.
#'
#' mufflyaccess also owns the **scenario dictionary** ([urps_scenarios()]): the
#' single versioned vocabulary of named forward-projection scenarios (baseline,
#' earlier/later retirement, fellowship expansion/constraint, reduced late-career
#' FTE, and composites). It fixes each scenario's *lever values* -- the definition
#' every repo agrees on and the enum a projection table keys on -- but never the
#' projection model, which stays in cliff.
#'
#' @section Design:
#' Values that must agree are *derived* from one another (never duplicated), each
#' `R/` file ends in a `stopifnot()` block that errors at load on an impossible
#' edit, and consumers pin a release commit rather than tracking the branch. See
#' the package README and `CONTRIBUTING.md` for the promotion checklist and the
#' consumer shim pattern.
#'
#' @keywords internal
"_PACKAGE"
