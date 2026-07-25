#' Canonical drive-time contour bands (minutes)
#'
#' The full set of drive-time thresholds the isochrone pipeline generates. The
#' primary/headline analysis band ([PRIMARY_ACCESS_BAND_MIN]) must be a member.
#' @format Integer vector, minutes, ascending.
#' @source isochrones/R/contour_bands.R (pipeline generation set)
#' @export
CANONICAL_BANDS <- c(30L, 60L, 120L, 180L)

#' Primary (headline) access drive-time band, in MINUTES
#'
#' The single drive-time threshold behind every headline access / coverage /
#' "desert" statistic ("within 60 minutes of a subspecialist"). Distinct from
#' [CANONICAL_BANDS]; MUST be one of its members.
#' @format Integer scalar (minutes).
#' @export
PRIMARY_ACCESS_BAND_MIN <- 60L

#' Primary access band, in SECONDS (derived)
#'
#' `PRIMARY_ACCESS_BAND_MIN * 60` -- the `range` value (seconds) that selects the
#' primary band in the Step-4 access tables (`range == 3600`). Derived; never set
#' independently.
#' @format Integer scalar (seconds).
#' @export
PRIMARY_ACCESS_BAND_SEC <- PRIMARY_ACCESS_BAND_MIN * 60L

# ---- fail-loud validation (runs at namespace load) --------------------------
stopifnot(
  "PRIMARY_ACCESS_BAND_MIN must be a single positive integer" =
    is.integer(PRIMARY_ACCESS_BAND_MIN) && length(PRIMARY_ACCESS_BAND_MIN) == 1L &&
    PRIMARY_ACCESS_BAND_MIN > 0L,
  "the headline band must be a member of CANONICAL_BANDS" =
    PRIMARY_ACCESS_BAND_MIN %in% CANONICAL_BANDS,
  "PRIMARY_ACCESS_BAND_SEC must equal MIN * 60" =
    is.integer(PRIMARY_ACCESS_BAND_SEC) && PRIMARY_ACCESS_BAND_SEC == PRIMARY_ACCESS_BAND_MIN * 60L,
  "CANONICAL_BANDS must be ascending, unique integers" =
    is.integer(CANONICAL_BANDS) && !is.unsorted(CANONICAL_BANDS, strictly = TRUE)
)

#' Return the canonical generation bands (minutes).
#' @return [CANONICAL_BANDS].
#' @export
get_canonical_bands <- function() CANONICAL_BANDS

#' Return the primary access band in the requested units.
#' @param units `"min"` (default) or `"sec"`.
#' @return Integer scalar -- [PRIMARY_ACCESS_BAND_MIN] or [PRIMARY_ACCESS_BAND_SEC].
#' @export
get_primary_access_band <- function(units = c("min", "sec")) {
  units <- match.arg(units)
  if (units == "sec") PRIMARY_ACCESS_BAND_SEC else PRIMARY_ACCESS_BAND_MIN
}
