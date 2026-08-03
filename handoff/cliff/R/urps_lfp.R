# urps_lfp.R  [APPLY IN: cliff, inside the projection recurrence loop]
#
# How cliff uses urps_p_active() to convert certified headcount to
# practicing headcount before computing supply_clinical_fte.
#
# DISTINCTION FROM urps_retirement.R:
#   urps_p_still_active() — PERMANENT exit survival curve:
#     P(still certified at age) by sex × pathway.
#     Drives the headcount survival curve. Called once per cohort cell per year.
#   urps_p_active()       — CONDITIONAL LFP:
#     P(actively practicing | still certified) by age × sex.
#     Captures sabbaticals, leaves of absence, part-time transitions that
#     do NOT appear in the certification record.
#
# PROJECTION RECURRENCE (per age × sex × pathway cell):
#   certified_n      <- prev_certified_n * (1 - urps_retirement_hazard(age, sex, pathway, ...))
#                       + entrants
#   practicing_n     <- certified_n * mufflyaccess::urps_p_active(age, sex)
#   supply_fte_cell  <- practicing_n * mufflyaccess::urps_fte_weight_sex(age, sex, pathway, ...)
#
# FULL COHORT FTE (all cells combined):
#   cohort$certified_n  <- ...
#   cohort$practicing_n <- cohort$certified_n *
#                          mufflyaccess::urps_p_active(cohort$age, cohort$sex)
#   supply_clinical_fte <- mufflyaccess::urps_effective_fte_sex(
#                            data.frame(age     = cohort$age,
#                                       sex     = cohort$sex,
#                                       pathway = cohort$pathway,
#                                       n       = cohort$practicing_n),
#                            scale = baseline_scale)
#
# Note: urps_effective_fte_sex() expects `n` to be the PRACTICING headcount
# (post-LFP), not the certified headcount. Do not double-apply the LFP
# adjustment by passing certified_n and separately scaling by p_active.
#
# SCENARIO INTEGRATION:
#   The LFP model has no dedicated scenario lever in the current registry.
#   The late-career FTE lever (lower_late_career_fte) already attenuates
#   contribution of older providers — applying an additional LFP attenuation
#   at the same ages would double-count. If a custom LFP scenario is needed,
#   it should scale the p_active output directly:
#
#   p <- mufflyaccess::urps_p_active(age, sex) * lfp_scale_factor
#   practicing_n <- certified_n * pmin(p, 1)
#
# sex values: "female" / "male" (lowercase).

if (!requireNamespace("mufflyaccess", quietly = TRUE))
  stop('Package "mufflyaccess" is required. renv::install("mufflyt/mufflyaccess").',
       call. = FALSE)

#' Apply LFP adjustment to a cohort data.frame.
#'
#' @param cohort data.frame with columns age (integer), sex (character),
#'   pathway (character), certified_n (numeric).
#' @return The same data.frame with a new column `practicing_n`.
urps_apply_lfp <- function(cohort) {
  need <- c("age", "sex", "certified_n")
  miss <- setdiff(need, names(cohort))
  if (length(miss))
    stop(sprintf("[urps_apply_lfp] missing required columns: %s",
                 paste(miss, collapse = ", ")), call. = FALSE)
  cohort$practicing_n <- cohort$certified_n *
    mufflyaccess::urps_p_active(cohort$age, cohort$sex)
  cohort
}
