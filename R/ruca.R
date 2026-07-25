#' Canonical 2-level RUCA breakpoint: first NON-metropolitan primary code
#'
#' @description USDA RUCA primary codes 1-3 are metropolitan; codes 4-10 are
#'   non-metropolitan (micropolitan, small-town, isolated rural). This single
#'   integer is the metro/rural cut used across the projects. The 3-level
#'   scheme's DISTINCT suburban/rural split (RUCA 7) is a SEPARATE threshold and
#'   is intentionally NOT derived from this constant.
#' @format Integer scalar.
#' @source USDA ERS RUCA codes; promoted from isochrones/R/utils/ruca_levels.R.
#' @export
RUCA_NONMETRO_MIN <- 4L

stopifnot(
  "[ruca] RUCA_NONMETRO_MIN must be a single integer strictly inside 1-10" =
    is.integer(RUCA_NONMETRO_MIN) && length(RUCA_NONMETRO_MIN) == 1L &&
    RUCA_NONMETRO_MIN > 1L && RUCA_NONMETRO_MIN < 10L
)
