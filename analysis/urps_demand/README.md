# URPS demand-model calibration

The demand side of the URPS workforce model — `urps_demand_fte()` /
`urps_gap_fte()` — is a **pre-calibration skeleton**: `urps_demand_params()`
ships every regression coefficient as `NA` and `calibration_status =
"not_calibrated"`, so `urps_demand_clinical_fte()` returns `NA` by design. This
directory is the **producer** that turns real survey data into a fitted
parameter artifact the package can serve.

The split mirrors the count/projection contracts:

| Piece | Where | Role |
|---|---|---|
| Skeleton + `urps_demand_params()` | `R/urps_demand.R` | the NA structure consumers wire against now |
| Ingestion contract | `R/urps_demand_calibration.R` | `urps_demand_params_schema()`, `validate_urps_demand_params()`, `read_urps_demand_params()` |
| **Fitting pipeline** | `analysis/urps_demand/fit_urps_demand.R` | fits the six regressions → validated CSV |
| Example artifact | `inst/extdata/urps_demand_params_example.csv` | a synthetic, typed stand-in (`calibration_status = "example"`) |

## Why it isn't calibrated yet

The conversion from a patient population to required clinical-FTE has to be
**estimated from utilization data**. The harder inputs are restricted-access:

| Setting | Source | Access | Notes |
|---|---|---|---|
| Office visits | **NAMCS 2023** | CDC NCHS Research Data Center (application + DUA + enclave) | subspecialty codes are restricted-use, not public |
| ED visits | **NHAMCS-ED 2022** | CDC NCHS RDC | survey ended after 2022 — 2022 is the final ED release |
| Outpatient | **HCUP SASD** | AHRQ HCUP, state-level DUA | NHAMCS-OPD was discontinued after 2017 — do **not** use it |
| Inpatient | **HCUP NIS 2023** | AHRQ HCUP, DUA | |
| Person panel (fitting frame) | **MEPS 2013–2017** | AHRQ public-use / Data Center | ~170k persons; the regression fitting set |

So this is a **data-access** blocker, not a code blocker. The pipeline below is
ready to run; it produces a fit the moment the data and the `survey` package are
available, and fails loud (never a fake fit) when they are not.

## The model

Six HWMM-style service equations (IHS Markit HWMM v5.19.20 structure), fit with
MEPS survey weights and calibrated to national totals via specialty × setting
scalars:

| Service | Model | Outcome |
|---|---|---|
| office / outpatient / home-health visits | negative binomial | annual count |
| hospitalization / ED probability | logistic | probability |
| hospital length of stay | Poisson | days/admission |

Covariates (`b_*` columns): age, sex, race/ethnicity, BMI, smoking, income (FPL),
insurance, managed care, chronic-condition count, urban/rural. Reference levels:
female, non-Hispanic white, ≥400% FPL, private insurance.

## Run it

```sh
# in an environment with the restricted data + the `survey` package:
export URPS_MEPS_PERSON_FILE=/path/to/meps_person_2013_2017.rds
export URPS_NATIONAL_TOTALS=/path/to/specialty_setting_totals.csv
Rscript analysis/urps_demand/fit_urps_demand.R
# -> analysis/urps_demand/urps_demand_params_fitted.csv  (validated on write)
```

`fit_urps_demand.R` extracts the coefficients into the exact
`urps_demand_params_schema()` layout, computes `nb_theta` for the NB rows and the
`calibration_scalar` per setting, then calls `validate_urps_demand_params()`
before writing — a malformed fit never reaches disk. Edit the MEPS variable-name
mappings (`SERVICES$*$outcome`, the survey-design columns, `RHS` terms) to match
your extract.

## Activate a fit

`read_urps_demand_params()` ingests + validates a fitted (or example) CSV and
returns a drop-in for `urps_demand_params()`:

```r
p <- mufflyaccess::read_urps_demand_params("analysis/urps_demand/urps_demand_params_fitted.csv")
attr(p, "calibration_status")   # "calibrated"
```

The final hookup is one option-aware branch in `urps_demand_params()` (owned by
`R/urps_demand.R`): when `getOption("mufflyaccess.urps_demand_params_path")` (or
an env var) points at a fitted artifact, delegate to `read_urps_demand_params()`
and serve it; otherwise return the NA skeleton. With that in place,
`urps_demand_fte()` and `urps_gap_fte()` light up across cliff and twostep with
**no consumer change** — they already call the demand functions unconditionally
and simply stop receiving `NA`. Bump `URPS_DEMAND_VERSION` to `1.0.0` on the
first real fit.

## Interim option

If the restricted data is far off, a `calibration_status = "literature_proxy"`
artifact — betas derived from published visits-per-FTE / utilization rates, each
sourced and clearly flagged provisional — validates against the same contract and
unblocks demand/gap numbers with a caveat. The validator already accepts that
status; only the sourced coefficient table would need to be authored.
