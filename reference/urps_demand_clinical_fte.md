# Compute demand_clinical_fte from a patient population and the fitted equations

Predicted ambulatory-visit demand for a patient population, converted to
clinical FTE. **Returns `NA_real_` while the demand model is
uncalibrated** (the
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)
NA skeleton). Once a fitted artifact is active –
`options(mufflyaccess.urps_demand_params_path = ...)` or
`MUFFLYACCESS_URPS_DEMAND_PARAMS`, see
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md)
– it evaluates the visit-count regressions per person, sums over the
population, applies the scenario demand levers, and divides by
`visits_per_fte`.

## Usage

``` r
urps_demand_clinical_fte(
  population,
  visits_per_fte,
  obesity_prev_shift = 0,
  insurance_expansion_factor = 1,
  managed_care_factor = 1,
  retail_clinic_share = 0
)
```

## Arguments

- population:

  A `data.frame` with columns matching the `b_*` covariate names in
  [`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)
  (age, sex, race, bmi, etc.) and a column `n` (population count per
  row).

- visits_per_fte:

  Annual URPS visits per full-time-equivalent provider (visits -\> FTE
  conversion denominator). No default; must be supplied.

- obesity_prev_shift:

  See
  [`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md).
  Default `0`.

- insurance_expansion_factor:

  See
  [`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md).
  Default `1`.

- managed_care_factor:

  Multiplier on total physician demand from HMO/ACO gatekeeping. Default
  `1` (no change). See
  [`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md).

- retail_clinic_share:

  Fraction of office-visit demand shifted to retail clinics, reducing
  URPS physician demand. Must be in \[0, 1). Default `0`. See
  [`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md).

## Value

Length-1 numeric `demand_clinical_fte` when the demand model is
calibrated; `NA_real_` while it is the uncalibrated skeleton.
`population` is a design-matrix `data.frame`: an `n` count column plus
covariate columns named as the fit's design terms (`age`, `sex_male`,
`race_black`, `bmi`, ...); an absent covariate is taken at its reference
level (`0`).

## Details

The pipeline, evaluated once
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md)
is calibrated (office + outpatient visit-count services drive
office-based URPS FTE):

1.  For each service type, evaluate the regression at each person's
    covariate vector to get predicted visit rate.

2.  Multiply by person count -\> expected visits.

3.  Apply demand scenario levers:

    - `obesity_prev_shift`: adjusts PFD-relevant covariate distribution.

    - `insurance_expansion_factor`: scales visits from newly insured
      persons.

    - `managed_care_factor`: multiplies total specialist visit demand.

    - `retail_clinic_share`: reduces physician demand by the share of
      visits that shift to retail clinics
      (`visits_physician = visits_total * (1 - share)`).

4.  Multiply by specialty x setting calibration scalar
    ([`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md)).

5.  Divide by `visits_per_fte` -\> `demand_clinical_fte`.

Use
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md)
to retrieve a scenario's lever bundle from the registry rather than
passing raw numeric values.

## See also

[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md)

Other URPS demand:
[`URPS_DEMAND_SCALARS_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_SCALARS_VERSION.md),
[`URPS_DEMAND_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_DEMAND_VERSION.md),
[`read_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_demand_params.md),
[`urps_demand_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_fte.md),
[`urps_demand_levers()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_levers.md),
[`urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params.md),
[`urps_demand_params_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_params_schema.md),
[`urps_demand_scalar()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalar.md),
[`urps_demand_scalars()`](https://mufflyt.github.io/mufflyaccess/reference/urps_demand_scalars.md),
[`validate_urps_demand_params()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_demand_params.md)

## Examples

``` r
levers <- urps_demand_levers("demand_managed_care_increase")
urps_demand_clinical_fte(
  population = data.frame(age = 50, sex = "female", n = 1000),
  visits_per_fte = 2000,
  managed_care_factor = levers$demand_managed_care_factor,
  retail_clinic_share = levers$demand_retail_clinic_share
) # NA_real_ until calibrated
#> [1] NA
```
