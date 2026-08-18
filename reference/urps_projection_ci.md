# Parametric-bootstrap confidence intervals for the URPS supply projection

Runs `B` parametric-bootstrap replicates of a user-supplied URPS
projection function and returns per-year, per-scenario quantile bounds
on `supply_headcount` and `supply_clinical_fte`.

## Usage

``` r
urps_projection_ci(
  project_fn,
  scenarios = "baseline",
  years = 2025:2045,
  B = 200,
  seed = 42,
  retirement_sigma_sd = 0.51,
  entrant_cv = 0.077,
  probs = c(0.025, 0.975)
)
```

## Arguments

- project_fn:

  A `function(scenario_id, years, param_draw)` that returns a
  `data.frame` containing at minimum the columns `year` (integer),
  `scenario_id` (character), `supply_headcount` (numeric), and
  `supply_clinical_fte` (numeric, may be `NA`). The `param_draw`
  argument is the list returned by
  [`urps_ci_param_draw()`](https://mufflyt.github.io/mufflyaccess/reference/urps_ci_param_draw.md);
  the function applies the perturbations to its recurrence engine as
  appropriate.

- scenarios:

  Character vector of registered scenario ids to bootstrap. Each must
  pass
  [`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md).
  Default `"baseline"`.

- years:

  Integer vector of projection years. Default `2025:2045`.

- B:

  Number of bootstrap replicates. Must be an integer `>= 10`. Default
  `200`.

- seed:

  Single integer RNG seed for reproducibility. Default `42`.

- retirement_sigma_sd:

  Passed to
  [`urps_ci_param_draw()`](https://mufflyt.github.io/mufflyaccess/reference/urps_ci_param_draw.md).
  Default `0.51`.

- entrant_cv:

  Passed to
  [`urps_ci_param_draw()`](https://mufflyt.github.io/mufflyaccess/reference/urps_ci_param_draw.md).
  Default `0.077`.

- probs:

  Length-2 numeric giving the lower and upper quantile probabilities.
  Both must be in (0, 1) and `probs[1] < probs[2]`. Default
  `c(0.025, 0.975)`.

## Value

A `data.frame` with one row per `(year, scenario_id)` combination and
columns:

- year:

  integer projection year

- scenario_id:

  character scenario identifier

- lower_headcount_95:

  lower quantile of `supply_headcount` across replicates (at `probs[1]`)

- upper_headcount_95:

  upper quantile of `supply_headcount` across replicates (at `probs[2]`)

- lower_fte_95:

  lower quantile of `supply_clinical_fte` across replicates (at
  `probs[1]`); `NA` if all replicate FTE values are `NA`

- upper_fte_95:

  upper quantile of `supply_clinical_fte` across replicates (at
  `probs[2]`); `NA` if all replicate FTE values are `NA`

## Details

**Three uncertainty sources** are modelled as independent normal draws
applied per replicate (HWMM uncertainty modelling convention):

- **Retirement timing (±1 yr at 95%):** a normal shift
  (`sd = retirement_sigma_sd = 0.51`) is added to the retirement-curve
  mu for every sex × pathway cell. This reflects uncertainty in the
  median retirement age derived from literature rather than
  ABOG-specific lapse records.

- **Entrant count (±15% at 95%):** a multiplicative normal scale
  (`mean = 1, cv = entrant_cv = 0.077`) is applied to the annual entrant
  count. This reflects year-to-year fellowship-output uncertainty and
  programme-capacity estimation error.

- **LFP intercept (additive, sd = 0.05):** a normal shift is added to
  the logistic LFP intercept for every sex cell, reflecting uncertainty
  in the anchor-point participation rates from the 2021 ACOG and 2022
  AMA surveys.

The three draws are statistically independent within each replicate. The
caller's `project_fn` is responsible for applying them;
[`urps_ci_param_draw()`](https://mufflyt.github.io/mufflyaccess/reference/urps_ci_param_draw.md)
documents the list contract.

## See also

[`urps_ci_param_draw()`](https://mufflyt.github.io/mufflyaccess/reference/urps_ci_param_draw.md),
[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md)

Other URPS projection CI:
[`urps_ci_param_draw()`](https://mufflyt.github.io/mufflyaccess/reference/urps_ci_param_draw.md)

## Examples

``` r
if (FALSE) { # \dontrun{
my_project_fn <- function(scenario_id, years, param_draw) {
  # apply param_draw perturbations inside your projection engine
  data.frame(
    year = years,
    scenario_id = scenario_id,
    supply_headcount = seq(1300, 1200, length.out = length(years)) *
      param_draw$entrant_scale,
    supply_clinical_fte = NA_real_
  )
}
ci <- urps_projection_ci(my_project_fn,
  scenarios = "baseline",
  years = 2025:2035, B = 50, seed = 1L
)
head(ci)
} # }
```
