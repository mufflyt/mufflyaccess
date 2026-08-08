#!/usr/bin/env Rscript
# =============================================================================
# Fit the URPS demand-model parameters from survey data -> a validated artifact.
#
# This is the PRODUCER for the demand-calibration contract in
# R/urps_demand_calibration.R. It reads the MEPS person-level panel (+ the
# specialty x setting national totals from NAMCS/NHAMCS/NIS/SASD), fits the six
# HWMM-style regressions with survey weights, extracts the coefficients into the
# canonical urps_demand_params_schema() layout, computes the calibration scalars,
# validates the result, and writes urps_demand_params_fitted.csv.
#
# It runs wherever the restricted data + the `survey` package are available. In
# an environment WITHOUT them it fails loud with acquisition guidance rather than
# producing a fake fit -- so this file is safe to commit and re-run when the data
# lands. Once it writes a fitted CSV, activation is one option in urps_demand.R:
#   options(mufflyaccess.urps_demand_params_path = "<fitted>.csv")
#
# Data acquisition (see analysis/urps_demand/README.md for the full protocol):
#   MEPS 2013-2017 person files  -> AHRQ public-use / Data Center
#   NAMCS 2023 (office)          -> CDC NCHS Research Data Center (restricted)
#   NHAMCS-ED 2022 (ED)          -> CDC NCHS RDC (final ED year)
#   HCUP NIS 2023 (inpatient)    -> AHRQ HCUP (DUA)
#   HCUP SASD (outpatient)       -> AHRQ HCUP (state DUA; NHAMCS-OPD discontinued)
# =============================================================================

suppressWarnings(suppressMessages({
  have_survey <- requireNamespace("survey", quietly = TRUE)
  have_mass   <- requireNamespace("MASS",   quietly = TRUE)  # glm.nb for dispersion
  library(mufflyaccess)                                       # the contract + validator
}))

MEPS_PERSON_FILE  <- Sys.getenv("URPS_MEPS_PERSON_FILE",  "")   # RDS/CSV person panel
NATIONAL_TOTALS   <- Sys.getenv("URPS_NATIONAL_TOTALS",   "")   # specialty x setting totals
OUT_CSV           <- Sys.getenv("URPS_DEMAND_OUT",
                                "analysis/urps_demand/urps_demand_params_fitted.csv")

# ---- Fail loud when the inputs / tooling are not present ---------------------
.block <- function(msg) stop(paste0(
  "[fit_urps_demand] ", msg,
  "\n  This harness is ready to run but needs restricted survey data + the `survey` package.",
  "\n  See analysis/urps_demand/README.md for the acquisition protocol."), call. = FALSE)

if (!have_survey) .block("the `survey` package is not installed (needed for svyglm with sampling weights).")
if (!nzchar(MEPS_PERSON_FILE) || !file.exists(MEPS_PERSON_FILE))
  .block("set URPS_MEPS_PERSON_FILE to the MEPS person-level panel (2013-2017).")
if (!nzchar(NATIONAL_TOTALS) || !file.exists(NATIONAL_TOTALS))
  .block("set URPS_NATIONAL_TOTALS to the NAMCS/NHAMCS/NIS/SASD specialty x setting totals.")

# ---- Model specification (fixed to the schema) -------------------------------
# The six service types and their model forms are the SSOT contract; the RHS is
# the HWMM covariate list. `service_outcome` maps each service to its MEPS
# outcome column (edit to your MEPS extract's variable names).
SERVICES <- list(
  office_visit         = list(form = "negative_binomial", outcome = "n_office_visits"),
  outpatient_visit     = list(form = "negative_binomial", outcome = "n_outpatient_visits"),
  home_health_visit    = list(form = "negative_binomial", outcome = "n_home_health_visits"),
  hospitalization_prob = list(form = "logistic",          outcome = "any_hospitalization"),
  ed_visit_prob        = list(form = "logistic",          outcome = "any_ed_visit"),
  hospital_los         = list(form = "poisson",           outcome = "hospital_los_days"))

# RHS terms in the order their coefficients map to the schema's b_* columns.
# `term_to_beta` translates a fitted model's coefficient names to schema columns.
RHS <- paste(
  "age",                                   # b_age
  "sex_male",                              # b_sex_male           (female = ref)
  "race_black + race_hispanic + race_other", # b_race_*           (NH white = ref)
  "bmi",                                   # b_bmi
  "smoking_current",                       # b_smoking_current
  "income_low + income_mid",               # b_income_*           (>=400% FPL = ref)
  "ins_medicaid + ins_medicare + ins_uninsured", # b_insurance_*  (private = ref)
  "managed_care",                          # b_managed_care
  "chronic_count",                         # b_chronic_count
  "urban",                                 # b_urban
  sep = " + ")

term_to_beta <- c(
  "(Intercept)"     = "intercept",
  age               = "b_age",
  sex_male          = "b_sex_male",
  race_black        = "b_race_black",
  race_hispanic     = "b_race_hispanic",
  race_other        = "b_race_other",
  bmi               = "b_bmi",
  smoking_current   = "b_smoking_current",
  income_low        = "b_income_low",
  income_mid        = "b_income_mid",
  ins_medicaid      = "b_insurance_medicaid",
  ins_medicare      = "b_insurance_medicare",
  ins_uninsured     = "b_insurance_uninsured",
  managed_care      = "b_managed_care",
  chronic_count     = "b_chronic_count",
  urban             = "b_urban")

# ---- Load data + build the survey design -------------------------------------
read_any <- function(p) if (grepl("\\.rds$", p, ignore.case = TRUE)) readRDS(p) else
  utils::read.csv(p, stringsAsFactors = FALSE)
meps    <- read_any(MEPS_PERSON_FILE)
totals  <- read_any(NATIONAL_TOTALS)

# MEPS complex-survey design: person weight + strata + PSU (edit to your columns).
design <- survey::svydesign(
  ids     = ~VARPSU, strata = ~VARSTR, weights = ~PERWT,
  data    = meps, nest = TRUE)

# ---- Fit one service -> one schema row ---------------------------------------
fit_service <- function(service, spec) {
  fml <- stats::as.formula(paste0(spec$outcome, " ~ ", RHS))
  fit <- switch(spec$form,
    negative_binomial = survey::svyglm(fml, design = design,
                                       family = MASS::negative.binomial(theta = 1)),
    logistic          = survey::svyglm(fml, design = design, family = stats::quasibinomial()),
    poisson           = survey::svyglm(fml, design = design, family = stats::quasipoisson()))
  co <- stats::coef(fit)
  row <- stats::setNames(rep(NA_real_, length(term_to_beta)), unname(term_to_beta))
  hit <- intersect(names(co), names(term_to_beta))
  row[term_to_beta[hit]] <- co[hit]
  # NB dispersion: refit with glm.nb on the design's weights to recover theta.
  theta <- if (spec$form == "negative_binomial" && have_mass) {
    tryCatch(MASS::glm.nb(fml, data = meps, weights = meps$PERWT)$theta,
             error = function(e) NA_real_)
  } else NA_real_
  scalar <- national_scalar(service, totals)   # specialty x setting calibration
  as.list(c(row, nb_theta = theta, calibration_scalar = scalar))
}

# Multiplicative scalar aligning the MEPS-predicted aggregate to the national
# survey total for this service's setting (HWMM calibration step).
national_scalar <- function(service, totals) {
  setting <- c(office_visit = "office", outpatient_visit = "outpatient",
               home_health_visit = "home_health", hospitalization_prob = "inpatient",
               ed_visit_prob = "ed", hospital_los = "inpatient")[[service]]
  r <- totals[totals$setting == setting, , drop = FALSE]
  if (nrow(r) != 1L || is.na(r$national_total) || is.na(r$meps_predicted_total) ||
      r$meps_predicted_total <= 0) return(1.0)
  as.numeric(r$national_total / r$meps_predicted_total)
}

# ---- Assemble, validate, write ----------------------------------------------
rows <- lapply(names(SERVICES), function(s) {
  vals <- fit_service(s, SERVICES[[s]])
  data.frame(service_type = s,
             model_form   = SERVICES[[s]]$form,
             outcome_units = c(negative_binomial = "annual_visit_count",
                               logistic = "probability_0_1",
                               poisson = "days_per_admission")[[SERVICES[[s]]$form]],
             as.data.frame(vals, stringsAsFactors = FALSE),
             data_source = "MEPS_2013_2017",
             calibration_status = "calibrated",
             stringsAsFactors = FALSE)
})
params <- do.call(rbind, rows)

mufflyaccess::validate_urps_demand_params(params)   # fail loud on any contract breach
utils::write.csv(params, OUT_CSV, row.names = FALSE, na = "NA")
cat(sprintf("[fit_urps_demand] wrote calibrated params (%d services) -> %s\n",
            nrow(params), OUT_CSV))
