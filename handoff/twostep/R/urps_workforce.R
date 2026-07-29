# urps_workforce.R   [APPLY IN: twostep]
#
# twostep consumes the national/CONUS URPS workforce count from mufflyaccess and
# never derives or hardcodes it. twostep is geography-aware: the access analysis
# runs on a specific geography (national roster vs. contiguous-US), so the count
# MUST carry the matching geography. Pass it explicitly.
# (Per ARCHITECTURE.md: isochrones builds the roster, mufflyaccess serves the
#  number, twostep computes spatial access on top of it.)

#' National / CONUS URPS workforce count for twostep (from mufflyaccess).
#' @param geography "national" or "conus" -- MUST match the geography of the
#'   access analysis (denominators, isochrone bands) it is paired with.
#' @param include_urology FALSE = ABOG only; TRUE = ABOG + ABU net-new.
#' @param year measure year (default 2023).
#' @param measure "board_certified_active" (default) or "roster_snapshot".
#' @return integer active count.
urps_workforce_n <- function(geography, include_urology = TRUE, year = 2023L,
                             measure = "board_certified_active") {
  if (!requireNamespace("mufflyaccess", quietly = TRUE))
    stop('Package "mufflyaccess" is required. renv::install("mufflyt/mufflyaccess").',
         call. = FALSE)
  stopifnot(geography %in% c("national", "conus"))
  as.integer(mufflyaccess::urps_count(
    year = year, measure = measure, geography = geography,
    include_urology = include_urology, incomplete = "error"))
}

# The geography passed here must be the SAME geography used for the population
# denominator and the isochrone access bands -- do not mix a CONUS access surface
# with a national workforce total. E.g. a contiguous-US access run uses:
#   urps_workforce_n("conus", include_urology = TRUE)   # 1329 (2023 active)
# and a national run uses:
#   urps_workforce_n("national", include_urology = TRUE) # 1332 (2023 active)
