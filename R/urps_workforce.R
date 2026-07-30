#' Deprecated frozen URPS workforce constants
#'
#' @description **Deprecated -- use [urps_count()].** `URPS_COUNT_ABOG_ONLY_2025`
#'   (1031) and `URPS_COUNT_ABOG_PLUS_ABU_2025` (1339) are the **2025
#'   `roster_snapshot`** values (ABOG-only and ABOG + ABU), *not* the 2023
#'   board-certified active count (which under contract v3.0.0 is 1027 / 1306).
#'   The bare `_2025` suffix cannot express the measure/geography a value belongs
#'   to; [urps_count()] does, explicitly.
#'
#'   The replacement is
#'   `urps_count(2025, "roster_snapshot", "national", include_urology = ...)`.
#'   They are retained as **active bindings that warn on access** and return the
#'   value, so existing references keep working while surfacing the deprecation
#'   (installed in `.onLoad()`).
#' @name urps_deprecated_constants
#' @seealso [urps_count()], [urps_lineage()]
#' @rawNamespace export(URPS_COUNT_ABOG_ONLY_2025)
#' @rawNamespace export(URPS_COUNT_ABOG_PLUS_ABU_2025)
NULL
