# urps_fte_sex.R  [APPLY IN: cliff, replacing urps_effective_fte() calls that
#                  have per-provider sex in the cohort]
#
# Drop-in upgrade from urps_effective_fte() / urps_fte_scale() to the
# sex-stratified OLS hours model introduced in mufflyaccess 0.8+.
#
# BEFORE (pathway-only, no sex):
#   counts <- data.frame(age, pathway, n)          # no sex column
#   scale  <- mufflyaccess::urps_fte_scale(counts)
#   fte    <- mufflyaccess::urps_effective_fte(counts, scale)
#
# AFTER (sex-stratified, preferred when sex data are available):
#   counts <- data.frame(age, sex, pathway, n)     # add sex column
#   scale  <- mufflyaccess::urps_fte_scale_sex(counts)
#   fte    <- mufflyaccess::urps_effective_fte_sex(counts, scale)
#
# sex values: "female" / "male" (lowercase).
# pathway values: "ABOG" / "ABU" (unchanged from existing contract).
#
# The scale must be computed ONCE from the 2023 baseline cohort and reused
# for all projection years so FTE is comparable across time. Do NOT recompute
# the scale each year — that would anchor each year to its own headcount and
# destroy the FTE trend.
#
# KEY DIFFERENCE IN NORMALIZATION:
#   urps_effective_fte()     -> rel_to_peak units (peak = 1.0 per provider)
#   urps_effective_fte_sex() -> hrs/40 units (40 hrs/wk = 1.0 FTE per provider)
#   Peak subspecialist FTE is ~1.375 (male ABOG at 47) under the sex model.
#   The scale factor absorbs this difference; the projection FTE column is
#   still anchored to headcount and is directly comparable.
#
# For the scenario late-career FTE lever (lower_late_career_fte):
#   sc  <- mufflyaccess::urps_scenario("lower_late_career_fte")
#   fte <- mufflyaccess::urps_effective_fte_sex(
#            counts, scale,
#            late_from_age = sc$late_career_fte_onset_age,
#            late_factor   = sc$late_career_fte_factor)
#
# If per-provider sex is NOT available in the cliff cohort, keep using
# urps_effective_fte() with the pathway-only model. Do not guess sex or
# apply a fixed 50/50 split without documenting the assumption.

if (!requireNamespace("mufflyaccess", quietly = TRUE))
  stop('Package "mufflyaccess" is required. renv::install("mufflyt/mufflyaccess").',
       call. = FALSE)

#' Compute supply_clinical_fte for one projection row (sex-stratified).
#'
#' @param cohort data.frame(age, sex, pathway, n) for the year and geography
#'   being projected.
#' @param baseline_scale The scale from urps_fte_scale_sex() on the 2023
#'   baseline cohort. Compute once; pass every year.
#' @param scenario_id A registered urps_scenario_id (default "baseline").
#' @return Length-1 numeric: supply_clinical_fte for this row.
urps_supply_clinical_fte_sex <- function(cohort, baseline_scale,
                                          scenario_id = "baseline") {
  sc <- mufflyaccess::urps_scenario(scenario_id)
  mufflyaccess::urps_effective_fte_sex(
    cohort,
    scale         = baseline_scale,
    late_from_age = sc$late_career_fte_onset_age,
    late_factor   = sc$late_career_fte_factor
  )
}
