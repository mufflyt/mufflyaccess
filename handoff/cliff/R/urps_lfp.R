# urps_lfp.R  [APPLY IN: cliff, inside the projection recurrence loop]
#
# How cliff composes the three supply adjustments in order:
#
#   STEP 1 — RETIREMENT SURVIVAL  (urps_retirement.R)
#     certified_n[t] <- certified_n[t-1] *
#                       (1 - urps_retirement_hazard(age, sex, pathway, shift_years)) +
#                       entrants[t]
#
#   STEP 2 — LABOR FORCE PARTICIPATION  (urps_lfp.R)
#     practicing_n[t] <- certified_n[t] * urps_p_active(age, sex)
#     — or call urps_apply_lfp(cohort) to add practicing_n in one shot
#
#   STEP 3 — FTE WEIGHT  (urps_fte_sex.R)
#     supply_clinical_fte[t] <- urps_effective_fte_sex(
#       data.frame(age, sex, pathway, n = practicing_n), scale = baseline_scale)
#     — or call urps_supply_fte_sex(cohort, baseline_scale) to do steps 2+3 at once
#
# PREFERRED PATTERN (steps 2+3 combined via urps_supply_fte_sex):
#
#   # --- ONE-TIME SETUP (2023 baseline) ------------------------------------
#   baseline_certified <- data.frame(age, sex, pathway, certified_n)
#   baseline_practicing <- mufflyaccess::urps_apply_lfp(baseline_certified)
#   baseline_scale <- mufflyaccess::urps_fte_scale_sex(
#     data.frame(age     = baseline_practicing$age,
#                sex     = baseline_practicing$sex,
#                pathway = baseline_practicing$pathway,
#                n       = baseline_practicing$practicing_n))
#
#   # --- EACH PROJECTION YEAR (2024 .. 2040) --------------------------------
#   cohort_t$certified_n <- cohort_prev$certified_n *
#     (1 - mufflyaccess::urps_retirement_hazard(
#            cohort_prev$age, cohort_prev$sex, cohort_prev$pathway,
#            retirement_shift_years = sc$retirement_shift_years)) +
#     entrants_t
#
#   proj_row$supply_clinical_fte <- mufflyaccess::urps_supply_fte_sex(
#     cohort_t,          # needs: age, sex, pathway, certified_n
#     baseline_scale,
#     late_from_age = sc$late_career_fte_onset_age,
#     late_factor   = sc$late_career_fte_factor)
#
# DISTINCTION FROM urps_retirement.R:
#   urps_p_still_active() — PERMANENT exit: P(still certified at age).
#     Drives certified_n via the hazard. Once retired, the provider is gone.
#   urps_p_active()       — CONDITIONAL participation: P(actively practicing |
#     still certified). Captures sabbaticals, leaves of absence, part-time
#     transitions that don't appear in the ABOG certification record.
#
# DOUBLE-APPLY WARNING:
#   urps_supply_fte_sex() applies LFP internally. Do NOT also multiply
#   certified_n by p_active before passing to it — that applies LFP twice.
#   Call either:
#     (a) urps_supply_fte_sex(cohort_with_certified_n, scale)  [LFP applied inside]
#     (b) urps_effective_fte_sex(cohort_with_practicing_n, scale)  [LFP already done]
#
# SCALE INVARIANT:
#   baseline_scale is computed ONCE from the 2023 baseline practicing cohort
#   and reused for ALL projection years. Never recompute it per year — that
#   would anchor each year to its own headcount and destroy the FTE trend.
#
# SCENARIO INTEGRATION:
#   retirement_shift_years: passed to urps_retirement_hazard() — shifts the
#     logistic survival curve earlier (-) or later (+).
#   late_career_fte_onset_age / late_career_fte_factor: passed to
#     urps_supply_fte_sex() — scales FTE weight for providers >= onset_age.
#   No dedicated LFP scenario lever exists; the late-career FTE lever already
#   covers the same cohort. Adding a separate LFP multiplier would double-count.

if (!requireNamespace("mufflyaccess", quietly = TRUE))
  stop('Package "mufflyaccess" is required. renv::install("mufflyt/mufflyaccess").',
       call. = FALSE)

# Example: compute supply_clinical_fte for one projection year.
# Replace `cohort_t` and `sc` with your actual objects.
example_projection_year <- function(cohort_t, baseline_scale, scenario_id = "baseline") {
  sc <- mufflyaccess::urps_scenario(scenario_id)
  mufflyaccess::urps_supply_fte_sex(
    cohort_t,
    baseline_scale = baseline_scale,
    late_from_age  = sc$late_career_fte_onset_age,
    late_factor    = sc$late_career_fte_factor
  )
}
