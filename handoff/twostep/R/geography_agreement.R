# ==============================================================================
# geography_agreement.R
#
# Reusable guard for the ONE place a workforce numerator and a population/demand
# denominator are combined into a supply-to-population measure: they MUST share
# the same geography. Use this wherever such a combination is introduced.
#
# IMPORTANT (why this is a helper, not a call site here): twostep's E2SFCA does
# NOT combine a *national* workforce total with a *national* population
# denominator. Its supply (provider points) and demand (tract population) are
# SPATIAL layers evaluated per location within a single study area, already
# unified by a shared equal-area CRS (E2SFCA_AREA_CRS = EPSG:5070; see
# two_step_floating_catchment.R). There is no national-total call site, so no
# assertion is bolted onto one. This helper exists for any future/consumer path
# that pairs a national or geography-scoped workforce count (e.g.
# mufflyaccess::urps_count(geography = ...)) with a matching population
# denominator -- so the numerator and denominator can never silently disagree on
# geography.
# ==============================================================================

#' Assert a workforce numerator and its denominator share one geography.
#'
#' Fails loudly when a supply-to-population measure would combine counts from
#' different geographies (e.g. a national workforce numerator over a CONUS
#' denominator). Geography strings are compared case-insensitively after
#' trimming; normalize with [mufflyaccess::urps_count()]'s accepted values
#' (`"national"`, `"conus"`) upstream.
#'
#' @param numerator_geography Geography of the workforce numerator (scalar string).
#' @param denominator_geography Geography of the population/demand denominator.
#' @param context Optional label for the error message (where the combination happens).
#' @return Invisibly `TRUE` when they agree; otherwise stops.
#' @examples
#' assert_same_geography("national", "national")
#' \dontrun{ assert_same_geography("national", "conus") }  # errors
#' @export
assert_same_geography <- function(numerator_geography, denominator_geography,
                                  context = "supply-to-population measure") {
  norm <- function(x) tolower(trimws(as.character(x)))
  if (length(numerator_geography) != 1L || length(denominator_geography) != 1L)
    stop("[geography] numerator and denominator geography must each be a single value.",
         call. = FALSE)
  base::stopifnot(identical(norm(numerator_geography), norm(denominator_geography)))
  if (!identical(norm(numerator_geography), norm(denominator_geography)))
    stop(sprintf("[geography] %s combines a %s numerator with a %s denominator; they must share one geography.",
                 context, numerator_geography, denominator_geography), call. = FALSE)
  invisible(TRUE)
}
