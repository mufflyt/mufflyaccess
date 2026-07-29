#' Deprecated frozen URPS workforce constants
#'
#' @description **Deprecated -- use [urps_count()].** `URPS_COUNT_ABOG_ONLY_2025`
#'   (1031) and `URPS_COUNT_ABOG_PLUS_ABU_2025` (1339) carry an ambiguous `_2025`
#'   suffix: it labels the workforce-model baseline year, but the numbers are the
#'   **2023 measure-year** active workforce (a distinction [urps_count()] carries
#'   explicitly via `measure_year` / `snapshot_date` / `model_baseline_year`).
#'
#'   They are retained as **active bindings that warn on access** and return the
#'   value, so existing references keep working while surfacing the deprecation.
#'   Call [urps_count()] instead. Created in `.onLoad()`.
#' @name urps_deprecated_constants
#' @seealso [urps_count()], [urps_counts()]
#' @rawNamespace export(URPS_COUNT_ABOG_ONLY_2025)
#' @rawNamespace export(URPS_COUNT_ABOG_PLUS_ABU_2025)
NULL
