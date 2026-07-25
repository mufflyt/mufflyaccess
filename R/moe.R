#' ACS margin-of-error z multipliers and the 90->95 conversion factor
#'
#' @description ACS publishes margins of error at the 90% confidence level:
#'   `MOE_90 = ACS_MOE_Z90 * SE`. The Census-documented rounded multiplier is
#'   **1.645** -- do NOT substitute `qnorm(0.95)` (= 1.6449); the rounded value
#'   is the published convention and changing it would move every derived SE/CI.
#'   A 95% CI half-width = `MOE_90 * MOE90_TO_CI95_FACTOR`. Reference these
#'   constants rather than re-deriving `1.96 / 1.645` inline.
#' @format numeric scalars. `MOE90_TO_CI95_FACTOR` is derived (`CI_Z95/ACS_MOE_Z90`, ~1.1915).
#' @source U.S. Census Bureau, "Understanding and Using ACS Data" (MOE appendix);
#'   promoted from isochrones/R/moe_propagation.R.
#' @export
ACS_MOE_Z90 <- 1.645
#' @rdname ACS_MOE_Z90
#' @export
CI_Z95 <- 1.96
#' @rdname ACS_MOE_Z90
#' @export
MOE90_TO_CI95_FACTOR <- CI_Z95 / ACS_MOE_Z90

stopifnot(
  "[moe] ACS_MOE_Z90 must be the Census 90% multiplier 1.645" = ACS_MOE_Z90 == 1.645,
  "[moe] CI_Z95 must be the 95% multiplier 1.96"              = CI_Z95 == 1.96,
  "[moe] factor must equal 1.96/1.645 (behavior-neutral)"     = MOE90_TO_CI95_FACTOR == 1.96 / 1.645
)
