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

This is **wired in**. `urps_demand_params()` checks
`getOption("mufflyaccess.urps_demand_params_path")` (then the env var
`MUFFLYACCESS_URPS_DEMAND_PARAMS`); when it points at a fitted artifact the
function delegates to `read_urps_demand_params()` and serves it, otherwise it
returns the NA skeleton:

```r
options(mufflyaccess.urps_demand_params_path =
        "analysis/urps_demand/urps_demand_params_fitted.csv")
mufflyaccess::urps_demand_fte(population, visits_per_fte = 2000)  # now a real FTE
```

`urps_demand_clinical_fte()` then evaluates the office + outpatient visit-count
regressions per person, applies the scenario demand levers, and divides by
`visits_per_fte` — so `urps_demand_fte()` and `urps_gap_fte()` light up across
cliff and twostep with **no consumer change** (they already call the demand
functions unconditionally and simply stop receiving `NA`). A misconfigured path
fails loud rather than silently serving `NA`. Bump `URPS_DEMAND_VERSION` to
`1.0.0` on the first real fit.

`population` is a design-matrix `data.frame`: an `n` count column plus covariate
columns named as the fit's design terms (`age`, `sex_male`, `race_black`, `bmi`,
…); an absent covariate is taken at its reference level (`0`).

## Free interim path: the literature_proxy (no restricted data, no money)

When the restricted data is out of reach, use the bundled
**`calibration_status = "literature_proxy"`** artifact. It validates against the
same contract as a real fit and unblocks demand/gap numbers today — clearly
flagged provisional.

```r
proxy <- system.file("extdata", "urps_demand_params_literature_proxy.csv",
                     package = "mufflyaccess")
options(mufflyaccess.urps_demand_params_path = proxy)
mufflyaccess::urps_demand_fte(population, visits_per_fte = 2500)   # a real number
```

Rebuild it (deterministic, free) with
[`build_literature_proxy.R`](build_literature_proxy.R), which derives its
coefficients from published priors:

- **Age gradient** `b_age ≈ 0.023/yr` — computed from this package's own Wu-2014
  PFD prevalence table (`WU2014_PFD_PREVALENCE`: 0.368 at 65–79 → 0.497 at 80+;
  Wu et al., *Obstet Gynecol* 2014, PMID 24463674). PFD prevalence is the demand
  driver for urogynecologic care.
- **Level** = PFD prevalence × a **subspecialist capture fraction** (0.05 —
  because most PFD is managed by general OB/GYN, not URPS subspecialists) ×
  visits-per-treated-woman. This capture fraction is the single most uncertain
  quantity and the main thing a real fit replaces; it is the dial to turn, and at
  0.05 baseline national demand lands near observed subspecialist supply
  (~1300 FTE), i.e. a modest baseline gap.
- **Covariate signs** (Medicare ↑, uninsured ↓, urban ↑, obesity ↑, women's
  condition) are directional priors from general ambulatory / women's-health
  utilization — **not** fitted magnitudes.

**Read this as relative, not absolute.** The age structure and scenario
responses are the reliable part; the absolute level rides on the two provisional
level constants at the top of `build_literature_proxy.R`. When the real MEPS/NAMCS
fit lands, swap `calibration_status` to `"calibrated"` and the same wiring serves
it with no consumer change.
