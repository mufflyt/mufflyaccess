# The URPS workforce scenario dictionary

The single, versioned vocabulary of named forward-projection scenarios
for the URPS workforce. Each row fixes the **lever values** that define
what a scenario *means* – everyone who writes or reads a projection
keyed on `scenario_id` agrees on the same definition. This is the enum
the cliff -\> mufflyaccess projection contract uses, and it replaces the
previously disjoint scenario sets scattered across the consumer repos.

## Usage

``` r
urps_scenarios()
```

## Value

A `data.frame`, one row per scenario, with columns:

- scenario_id:

  the stable identifier (the enum value)

- family:

  `"reference"`, `"retirement"`, `"entry"`, `"fte"`, or `"composite"`

- label:

  human-readable name

- entrant_multiplier:

  scales annual entrants (1 = baseline)

- retirement_shift_years:

  integer years to shift the retirement-hazard curve (negative = earlier
  exit; 0 = baseline)

- late_career_fte_factor:

  multiplies clinical FTE at/after the onset age (1 = no adjustment)

- late_career_fte_onset_age:

  age at which the FTE factor begins, or `NA`

- requires_fte_model:

  `TRUE` if the scenario needs the clinical-FTE model (a later phase) to
  be executed

- description:

  one-line statement of the scenario

## Details

mufflyaccess owns the **definitions**, not the model: the registry
states that (for example) `fellowship_plus_10pct` scales entrants by
1.10, but *how* an entrant multiplier, a retirement-hazard shift, or a
late-career FTE factor propagates through the projection is cliff's
engine (see `ARCHITECTURE.md`). Scenarios live in a four-axis lever
space with `baseline` as the neutral origin; composite scenarios are the
multiplicative/additive composition of single-lever components and are
cross-checked at load so the table cannot drift. FTE scenarios carry
`requires_fte_model = TRUE` because they depend on the age-specific
clinical-FTE model that is a later phase – a consumer can filter to what
it can execute today.

## See also

[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md),
[URPS_SCENARIO_REGISTRY_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_SCENARIO_REGISTRY_VERSION.md)

Other URPS scenarios:
[`URPS_SCENARIO_REGISTRY_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_SCENARIO_REGISTRY_VERSION.md),
[`is_urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/is_urps_scenario.md),
[`urps_scenario()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario.md),
[`urps_scenario_ids()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenario_ids.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md)

## Examples

``` r
urps_scenarios()[, c("scenario_id", "family", "label")]
#>                     scenario_id     family
#> 1                      baseline  reference
#> 2            retire_2yr_earlier retirement
#> 3            retire_5yr_earlier retirement
#> 4              retire_2yr_later retirement
#> 5         fellowship_plus_10pct      entry
#> 6        fellowship_constrained      entry
#> 7         lower_late_career_fte        fte
#> 8    demand_insurance_expansion     demand
#> 9       demand_obesity_increase     demand
#> 10                demand_equity     demand
#> 11 demand_managed_care_increase     demand
#> 12   demand_retail_clinic_shift     demand
#> 13         combined_pessimistic  composite
#> 14          combined_investment  composite
#>                                                                      label
#> 1                                                                 Baseline
#> 2                                               Retirement 2 years earlier
#> 3                                               Retirement 5 years earlier
#> 4                                                 Retirement 2 years later
#> 5                                                   Fellowship output +10%
#> 6                                     Fellowship output constrained (-10%)
#> 7                                         Reduced late-career clinical FTE
#> 8                Increased insurance coverage (+10pp uninsured -> insured)
#> 9              Increased obesity prevalence (+5 percentage points by 2035)
#> 10 Reduced access barriers (equity: income + race + insurance convergence)
#> 11   Increased managed care / ACO enrollment (-15% demand via gatekeeping)
#> 12  Expanded retail clinic capacity (10% of office visits shift to retail)
#> 13                                                    Combined pessimistic
#> 14                                           Combined workforce investment
# the executable-today subset (no clinical-FTE model required):
subset(urps_scenarios(), !requires_fte_model, scenario_id)
#>                     scenario_id
#> 1                      baseline
#> 2            retire_2yr_earlier
#> 3            retire_5yr_earlier
#> 4              retire_2yr_later
#> 5         fellowship_plus_10pct
#> 6        fellowship_constrained
#> 8    demand_insurance_expansion
#> 9       demand_obesity_increase
#> 10                demand_equity
#> 11 demand_managed_care_increase
#> 12   demand_retail_clinic_shift
#> 14          combined_investment
```
