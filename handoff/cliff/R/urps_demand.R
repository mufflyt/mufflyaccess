# urps_demand.R  [APPLY IN: cliff, once per projection row]
#
# Wires supply, demand, and gap into a single projection row.
#
# FULL PROJECTION RECURRENCE (per year t, scenario s, geography g):
#
#   # SUPPLY — three steps, each in mufflyaccess
#   cohort_t$certified_n <- cohort_prev$certified_n *
#     (1 - mufflyaccess::urps_retirement_hazard(
#            cohort_prev$age, cohort_prev$sex, cohort_prev$pathway,
#            retirement_shift_years = sc$retirement_shift_years)) +
#     entrants_t
#
#   supply_clinical_fte <- mufflyaccess::urps_supply_fte_sex(
#     cohort_t,          # needs: age, sex, pathway, certified_n
#     baseline_scale,    # computed ONCE from 2023 baseline; never recomputed
#     late_from_age = sc$late_career_fte_onset_age,
#     late_factor   = sc$late_career_fte_factor)
#
#   # DEMAND — one call; returns NA until MEPS/NAMCS equations are calibrated
#   demand_clinical_fte <- mufflyaccess::urps_demand_fte(
#     population_t,      # data.frame(age, sex, race, bmi, ..., n)
#     visits_per_fte  = URPS_VISITS_PER_FTE,
#     scenario_id     = scenario_id)   # levers resolved from registry internally
#
#   # GAP — closes the triangle; NA when demand is NA
#   gap_fte <- mufflyaccess::urps_gap_fte(supply_clinical_fte, demand_clinical_fte)
#
#   # EMIT — one row of the projection contract table
#   proj_row <- data.frame(
#     year                 = t,
#     scenario_id          = scenario_id,
#     specialty            = "URPS",
#     certification_pathway = "ABOG_PLUS_ABU",
#     geography_type       = "national",
#     geography_id         = "US",
#     supply_headcount     = sum(cohort_t$certified_n),
#     supply_clinical_fte  = supply_clinical_fte,
#     demand_clinical_fte  = demand_clinical_fte,   # NA until calibrated
#     gap_fte              = gap_fte,               # NA until calibrated
#     entrants             = sum(entrants_t),
#     exits                = sum(exits_t),
#     net_change           = sum(entrants_t) - sum(exits_t))
#
# SETUP (run ONCE at projection initialisation, not per year):
#
#   sc             <- mufflyaccess::urps_scenario(scenario_id)
#   baseline_scale <- mufflyaccess::urps_fte_scale_sex(
#                       baseline_practicing_cohort)   # 2023 practicing cohort only
#
# NULL DEMAND CONTRACT:
#   urps_demand_fte() returns NA_real_ for ALL scenarios until
#   urps_demand_params()$calibration_status != "not_calibrated".
#   NA is explicitly allowed by the projection contract for demand_clinical_fte
#   and gap_fte (both optional columns). cliff should call urps_demand_fte()
#   unconditionally every year; the NA propagates correctly and is validated.
#
# WHEN DEMAND IS CALIBRATED:
#   No cliff code changes needed. Once mufflyaccess ships coefficients
#   (URPS_DEMAND_VERSION >= "1.0.0"), urps_demand_fte() returns a real value
#   and gap_fte becomes non-NA automatically.
#
# VISITS_PER_FTE:
#   This is cliff's responsibility to determine — the annual URPS patient visits
#   a full-time provider handles. A reasonable placeholder from the AMA Physician
#   Practice Benchmark Survey is 2000-2500 visits/yr for subspecialists. Once
#   demand equations are calibrated and validated against NAMCS totals, revisit
#   this constant alongside the calibration scalars in urps_demand_scalars().
#
# EXECUTABLE TODAY (no demand model required):
#   mufflyaccess::urps_scenarios() %>%
#     filter(!requires_fte_model, !requires_demand_model)
#   # -> baseline, retire_*, fellowship_*, combined_investment

if (!requireNamespace("mufflyaccess", quietly = TRUE))
  stop('Package "mufflyaccess" is required. renv::install("mufflyt/mufflyaccess").',
       call. = FALSE)

URPS_VISITS_PER_FTE <- 2200L   # placeholder — revisit when demand is calibrated

#' Compute one projection row (supply + demand + gap).
#'
#' @param cohort_t data.frame(age, sex, pathway, certified_n) for year t.
#' @param population_t data.frame(age, sex, race, bmi, ..., n) for year t.
#' @param baseline_scale Scale from urps_fte_scale_sex() on the 2023 cohort.
#' @param scenario_id A registered urps_scenario_id.
#' @param t Integer projection year.
#' @param entrants_t Numeric entrant count for year t.
#' @param exits_t Numeric exit count for year t.
#' @return A one-row projection data.frame conforming to the v1.1.0 contract.
urps_projection_row <- function(cohort_t, population_t, baseline_scale,
                                 scenario_id = "baseline", t,
                                 entrants_t = NA_real_, exits_t = NA_real_) {
  sc <- mufflyaccess::urps_scenario(scenario_id)

  supply_clinical_fte <- mufflyaccess::urps_supply_fte_sex(
    cohort_t,
    baseline_scale = baseline_scale,
    late_from_age  = sc$late_career_fte_onset_age,
    late_factor    = sc$late_career_fte_factor)

  demand_clinical_fte <- mufflyaccess::urps_demand_fte(
    population_t,
    visits_per_fte = URPS_VISITS_PER_FTE,
    scenario_id    = scenario_id)

  gap_fte <- mufflyaccess::urps_gap_fte(supply_clinical_fte, demand_clinical_fte)

  net <- if (!is.na(entrants_t) && !is.na(exits_t)) entrants_t - exits_t else NA_real_

  data.frame(
    year                  = as.integer(t),
    scenario_id           = scenario_id,
    specialty             = "URPS",
    certification_pathway = "ABOG_PLUS_ABU",
    geography_type        = "national",
    geography_id          = "US",
    supply_headcount      = sum(cohort_t$certified_n),
    supply_clinical_fte   = supply_clinical_fte,
    demand_clinical_fte   = demand_clinical_fte,
    gap_fte               = gap_fte,
    entrants              = entrants_t,
    exits                 = exits_t,
    net_change            = net,
    stringsAsFactors      = FALSE)
}
