#!/usr/bin/env Rscript
# =============================================================================
# Build a LITERATURE-PROXY URPS demand-parameter table (no restricted data).
#
# When the restricted survey fit (fit_urps_demand.R) is out of reach, this
# produces a provisional coefficient table that (a) validates against the same
# contract as a real fit, (b) yields plausible, directionally-correct demand,
# and (c) is loudly flagged calibration_status = "literature_proxy" so nobody
# mistakes it for a MEPS/NAMCS fit. It is deterministic and free to run.
#
# Grounding of the load-bearing office/outpatient visit-count models:
#   * AGE gradient  <- this package's Wu-2014 PFD prevalence table
#     (WU2014_PFD_PREVALENCE): PFD prevalence 0.368 at 65-79 -> 0.497 at 80+,
#     a log-rate slope of ~0.023/yr, which we use as b_age. PFD prevalence is the
#     demand driver for urogynecologic care (Wu et al., Obstet Gynecol 2014;
#     PMID 24463674).
#   * LEVEL          <- PFD prevalence x an explicit, provisional care-seeking
#     fraction x visits-per-symptomatic-woman (both stated below). This is the
#     one genuinely data-hungry quantity; it is a documented assumption here.
#   * Covariate signs <- direction only, from general ambulatory-care and
#     women's-health utilization patterns (Medicare age effect up, uninsured
#     down, urban specialist access up, obesity up). Magnitudes are modest,
#     provisional placeholders -- NOT fitted estimates.
#
# Writes inst/extdata/urps_demand_params_literature_proxy.csv (aggregate, safe
# to commit -- no microdata). Activate with:
#   options(mufflyaccess.urps_demand_params_path =
#     system.file("extdata","urps_demand_params_literature_proxy.csv","mufflyaccess"))
# =============================================================================

suppressWarnings(suppressMessages(library(mufflyaccess)))

# ---- 1. Age gradient from the package's own Wu-2014 PFD table ---------------
wu <- WU2014_PFD_PREVALENCE[WU2014_PFD_PREVALENCE$condition == "any_PFD", ]
AGE_65_79_MID <- 72   # band centre for 65-79
AGE_80PLUS_MID <- 85  # representative age for 80+
B_AGE <- (log(wu$p_80plus) - log(wu$p_65_79)) / (AGE_80PLUS_MID - AGE_65_79_MID)

# ---- 2. Level assumptions (PROVISIONAL -- the part a real fit replaces) ------
# *** The single most uncertain quantity -- a real fit's main job to pin down. ***
# Most symptomatic PFD is managed by GENERAL OB/GYN, not URPS subspecialists, so
# the fraction of symptomatic women seen by a URPS SUBSPECIALIST each year is
# small. 0.05 lands baseline national demand near observed subspecialist supply
# (~1300 FTE), i.e. a modest baseline gap; treat it as the dial to turn.
CARE_SEEKING_FRACTION   <- 0.05   # symptomatic women seen by a URPS SUBSPECIALIST / yr
VISITS_PER_SYMPTOMATIC  <- 1.5    # annual URPS office visits per treated woman
OUTPATIENT_SHARE        <- 0.15   # outpatient-dept visits as a share of office
REF_AGE                 <- AGE_65_79_MID
ref_prev                <- wu$p_65_79
office_rate_at_ref      <- ref_prev * CARE_SEEKING_FRACTION * VISITS_PER_SYMPTOMATIC
# intercept so exp(intercept + B_AGE*REF_AGE) == office_rate_at_ref (other covars = 0)
INT_OFFICE     <- log(office_rate_at_ref) - B_AGE * REF_AGE
INT_OUTPATIENT <- INT_OFFICE + log(OUTPATIENT_SHARE)

# ---- 3. Directional covariate effects (provisional placeholders) ------------
# named by schema beta column; 0 = no adjustment (reference behaviour)
cov <- c(
  b_sex_male            = -2.00,  # URPS conditions predominantly affect women
  b_race_black          = -0.05,  # modest access differentials (direction only)
  b_race_hispanic       = -0.05,
  b_race_other          = -0.05,
  b_bmi                 =  0.010, # obesity raises PFD incidence
  b_smoking_current     =  0.00,
  b_income_low          = -0.15,  # lower specialist access at low income
  b_income_mid          = -0.05,
  b_insurance_medicaid  = -0.10,
  b_insurance_medicare  =  0.15,  # older, higher URPS use
  b_insurance_uninsured = -0.35,  # lowest access
  b_managed_care        = -0.05,  # gatekeeping slightly reduces direct access
  b_chronic_count       =  0.05,
  b_urban               =  0.20)  # specialist supply concentrated in metros

beta_cols <- c("intercept", "b_age", names(cov))
mk <- function(intercept, b_age, scale_betas = 1) {
  v <- c(intercept = intercept, b_age = b_age, cov * scale_betas)
  as.list(v[beta_cols])
}

# ---- 4. Assemble the 6 service rows -----------------------------------------
# Only office_visit + outpatient_visit enter the office-based FTE estimand in
# urps_demand_clinical_fte(); the other rows are filled (finite, contract-valid)
# but do not drive clinical FTE. nb_theta: positive on NB rows, NA otherwise.
rows <- list(
  office_visit         = c(mk(INT_OFFICE,     B_AGE),                 list(nb_theta = 1.5,  form = "negative_binomial", units = "annual_visit_count")),
  outpatient_visit     = c(mk(INT_OUTPATIENT, B_AGE),                 list(nb_theta = 1.2,  form = "negative_binomial", units = "annual_visit_count")),
  home_health_visit    = c(mk(INT_OFFICE - 3, B_AGE, 0.5),            list(nb_theta = 0.8,  form = "negative_binomial", units = "annual_visit_count")),
  hospitalization_prob = c(mk(-3.0,           0.020, 0.5),            list(nb_theta = NA_real_, form = "logistic", units = "probability_0_1")),
  ed_visit_prob        = c(mk(-2.2,           0.005, 0.5),            list(nb_theta = NA_real_, form = "logistic", units = "probability_0_1")),
  hospital_los         = c(mk(0.70,           0.005, 0.3),            list(nb_theta = NA_real_, form = "poisson",  units = "days_per_admission")))

df <- do.call(rbind, lapply(names(rows), function(svc) {
  r <- rows[[svc]]
  data.frame(
    service_type       = svc,
    model_form         = r$form,
    outcome_units      = r$units,
    intercept = r$intercept, b_age = r$b_age,
    b_sex_male = r$b_sex_male,
    b_race_black = r$b_race_black, b_race_hispanic = r$b_race_hispanic, b_race_other = r$b_race_other,
    b_bmi = r$b_bmi, b_smoking_current = r$b_smoking_current,
    b_income_low = r$b_income_low, b_income_mid = r$b_income_mid,
    b_insurance_medicaid = r$b_insurance_medicaid, b_insurance_medicare = r$b_insurance_medicare,
    b_insurance_uninsured = r$b_insurance_uninsured, b_managed_care = r$b_managed_care,
    b_chronic_count = r$b_chronic_count, b_urban = r$b_urban,
    nb_theta = r$nb_theta,
    calibration_scalar = 1.0,
    data_source = "literature_proxy:Wu2014_PFD+ambulatory_priors",
    calibration_status = "literature_proxy",
    stringsAsFactors = FALSE)
}))

# ---- 5. Validate against the contract + write -------------------------------
validate_urps_demand_params(df)   # fail loud if the proxy breaks the contract
out <- "inst/extdata/urps_demand_params_literature_proxy.csv"
utils::write.csv(df, out, row.names = FALSE, na = "NA")
cat(sprintf("[literature_proxy] b_age = %.4f (from Wu-2014); office intercept = %.3f\n",
            B_AGE, INT_OFFICE))
cat(sprintf("[literature_proxy] wrote %d service rows -> %s\n", nrow(df), out))
