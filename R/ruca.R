#' Canonical 2-level RUCA breakpoint: first NON-metropolitan primary code
#'
#' @description USDA RUCA primary codes 1-3 are metropolitan; codes 4-10 are
#'   non-metropolitan (micropolitan, small-town, isolated rural). This single
#'   integer is the metro/rural cut used across the projects. The 3-level
#'   scheme's DISTINCT suburban/rural split (RUCA 7) is a SEPARATE threshold and
#'   is intentionally NOT derived from this constant.
#' @format Integer scalar.
#' @source Primary: U.S. Department of Agriculture, Economic Research Service,
#'   Rural-Urban Commuting Area (RUCA) Codes,
#'   <https://www.ers.usda.gov/data-products/rural-urban-commuting-area-codes>
#'   (primary codes 1-3 metropolitan, 4-10 non-metropolitan). Promoted from
#'   isochrones/R/utils/ruca_levels.R.
#' @seealso [rurality_from_ruca()], which uses this breakpoint to classify codes.
#' @family rurality
#' @examples
#' RUCA_NONMETRO_MIN                   # 4L (codes 1-3 metro, 4-10 rural)
#' rurality_from_ruca(c(3, 4))         # "Metropolitan" "Rural"
#' @export
RUCA_NONMETRO_MIN <- 4L

stopifnot(
  "[ruca] RUCA_NONMETRO_MIN must be a single integer strictly inside 1-10" =
    is.integer(RUCA_NONMETRO_MIN) && length(RUCA_NONMETRO_MIN) == 1L &&
    RUCA_NONMETRO_MIN > 1L && RUCA_NONMETRO_MIN < 10L
)
