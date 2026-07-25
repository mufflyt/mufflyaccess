#' Total-female access-table denominator category label
#'
#' The `category` value marking the all-female-population row in the access
#' tables (`filter(category == DENOMINATOR_CATEGORY)`) -- the denominator for
#' every access percentage. The race categories are a DISTINCT
#' `"total_female_<race>"` prefixed family and are intentionally NOT this value.
#' @format Character scalar.
#' @source isochrones/R/access_categories.R
#' @export
DENOMINATOR_CATEGORY <- "total_female"

stopifnot(
  "DENOMINATOR_CATEGORY must be a single non-empty string" =
    is.character(DENOMINATOR_CATEGORY) && length(DENOMINATOR_CATEGORY) == 1L &&
    nzchar(DENOMINATOR_CATEGORY),
  "DENOMINATOR_CATEGORY must be the bare total-female label, NOT race-prefixed" =
    !grepl("^total_female_", DENOMINATOR_CATEGORY)
)
