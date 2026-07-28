# urps_baseline.R   [APPLY IN: cliff, replacing any independent baseline derivation]
#
# The ONLY way cliff obtains the national URPS baseline. cliff depends on a
# PINNED release of mufflyaccess and uses these values purely as INPUTS to
# projections / scenarios. Never derive or hardcode the baseline here.
# (Per ARCHITECTURE.md: isochrones builds the roster, mufflyaccess serves the
#  number, cliff models what happens next.)

#' National URPS baseline for cliff (sourced from mufflyaccess).
#' @param include_urology FALSE = ABOG-only (1031); TRUE = ABOG+ABU (1339).
#' @param year measure year (default 2023).
#' @return integer active count.
urps_baseline <- function(include_urology = FALSE, year = 2023L) {
  if (!requireNamespace("mufflyaccess", quietly = TRUE))
    stop('Package "mufflyaccess" is required. renv::install("mufflyt/mufflyaccess").',
         call. = FALSE)
  as.integer(mufflyaccess::urps_count(year = year, include_urology = include_urology))
}

# Drop-in for the old get_baseline("URPS"): route it through mufflyaccess so the
# workforce_projections_consolidated.csv baseline is no longer a separate SSOT.
# Example replacement inside manuscript/R/workforce_statistics.R:
#   get_baseline <- function(sub) {
#     if (identical(sub, "URPS")) return(urps_baseline(include_urology = TRUE))  # 1339
#     ... existing logic for other subspecialties ...
#   }
