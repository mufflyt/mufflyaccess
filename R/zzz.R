# Deprecated URPS workforce constants as warn-on-access active bindings.
# (Data objects cannot warn on access, so they are installed here.)

#' Deprecated 2025 URPS roster-snapshot count constants
#'
#' @description `URPS_COUNT_ABOG_ONLY_2025` (1031) and
#'   `URPS_COUNT_ABOG_PLUS_ABU_2025` (1339) are the 2025 `roster_snapshot`
#'   headcounts, kept as **deprecated** warn-on-access bindings. Use [urps_count()]
#'   instead:
#'   `urps_count(2025, "roster_snapshot", "national", include_urology = FALSE)` and
#'   the `include_urology = TRUE` variant. These are the 2025 roster, **not** the
#'   2023 `board_certified_active` count (1027 / 1306).
#' @name urps_count_2025_deprecated
#' @aliases URPS_COUNT_ABOG_ONLY_2025 URPS_COUNT_ABOG_PLUS_ABU_2025
#' @seealso [urps_count()]
#' @keywords internal
NULL

.onLoad <- function(libname, pkgname) {
  ns <- asNamespace(pkgname)
  make_dep <- function(name, value, hint) {
    force(name); force(value); force(hint)
    getter <- function() {
      warning(sprintf("%s is deprecated; use %s.", name, hint), call. = FALSE)
      value
    }
    if (exists(name, envir = ns, inherits = FALSE)) {
      if (bindingIsLocked(name, ns)) unlockBinding(name, ns)
      rm(list = name, envir = ns)
    }
    makeActiveBinding(name, getter, ns)
  }
  # These *_2025 values are the 2025 roster_snapshot (1031 / 1339), NOT the
  # canonical 2023 board_certified_active counts (1027 / 1306, contract v3.0.0;
  # 1332 was the retired v2.1.0 combined cell). The migration hint points at the
  # matching roster_snapshot cell.
  make_dep("URPS_COUNT_ABOG_ONLY_2025", 1031L,
           'urps_count(2025L, "roster_snapshot", "national", include_urology = FALSE)')
  make_dep("URPS_COUNT_ABOG_PLUS_ABU_2025", 1339L,
           'urps_count(2025L, "roster_snapshot", "national", include_urology = TRUE)')
}
