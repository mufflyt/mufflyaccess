# URPS observed workforce-exit panel

The retirement side of the URPS workforce model is, like demand, a **fail-loud
skeleton**: `mufflyaccess::urps_retirement_status()` reports `"not_ascertained"`
and `n_retired` is served as `NA`, never `0`, because the package refuses to
present an unobserved departure as zero. This directory is the **producer** that
turns raw provider records into the observed departure facts the package can
serve — and, once it runs, flips retirement to `"observed"`.

The split mirrors the count / demand contracts:

| Piece | Where | Role |
|---|---|---|
| Serving layer (base R) | `R/urps_exit_panel.R` | `urps_departures()`, `urps_exit_counts()`, `urps_exit_hazard_by_age_year()`, `validate_urps_exit_evidence()` — serve the frozen facts, fail loud until configured |
| **Panel builder** | `analysis/urps_exit_panel/build_exit_panel.R` | provider-month panel → confirmed exits → age × year hazard |
| Example artifacts | `inst/extdata/urps_observed_departures_example.csv`, `inst/extdata/urps_exit_hazard_by_age_year_example.csv` | synthetic, typed stand-ins the tests + `@examples` run against |

## Why a provider-**month** panel (not annual roster differences)

Diffing an annual roster answers "who is gone this year" but throws away the one
thing you need to trust the answer: **whether the person came back**. A
subspecialist can miss a year of Medicare billing (sabbatical, parental leave, a
locum stretch, a coding gap) and resume — annual differencing counts that as an
exit and then silently un-counts it a year later. Building at monthly resolution
first preserves the evidence to separate a **true exit** from a **temporary
disappearance**, and only *then* derives the annual numbers.

The pipeline is:

```
provider → month → observed evidence → practice state → exit episode → confirmed exit
```

### The evidence contract

Every source system (Medicare PECOS/carrier, NPPES, ABOG/ABU roster, Physician
Compare, mystery-call) normalizes to one tiny table before the panel is built —
enforced at the door by `validate_urps_exit_evidence()`:

| column | type | meaning |
|---|---|---|
| `provider_id` | chr | NPI (or canonical id) |
| `month` | Date | first-of-month |
| `source` | chr | which system saw them |
| `practice_evidence` | lgl | did *this* source see practice that month |

### Four evidence principles (priority order)

1. **Positive evidence beats absence.** An active month is proof of practice; an
   absent month is only a *candidate* for exit. A month is `active` iff **any**
   source has `practice_evidence == TRUE`.
2. **Absence must mature.** A first-absent month becomes a confirmed exit only
   after `CONFIRM_MONTHS` (default **12**) of continued absence. Providers whose
   trailing absence is shorter than the window are **censored** — not yet
   confirmed — and are excluded, never counted as `0`.
3. **Return beats exit.** Any later active month cancels a candidate exit and
   reclassifies the gap as `temporary_gap`. A departure is only ever a *trailing*
   absence run.
4. **Don't call every disappearance a retirement.** The broad outcome is
   `workforce_exit`; `exit_reason = "retired"` is the **subset** with explicit
   retirement evidence (board voluntary-relinquishment, Medicare opt-out with no
   return, NPPES deactivation reason / obituary). Absence alone is never
   `"retired"`.

## The three frozen artifacts

The builder freezes three CSVs. **`urps_provider_month_activity.csv` is the
source of truth**; the other two are reproducible derivatives of it.

| Artifact | Grain | Served by |
|---|---|---|
| `urps_provider_month_activity.csv` | provider × month (`active`, `practice_state`, `sources`) | (source of truth; not served directly) |
| `urps_observed_departures.csv` | one row / confirmed exit (`provider_id`, `exit_month`, `exit_reason`, `retirement_observed`) | `urps_departures()`, `urps_exit_counts()` |
| `urps_exit_hazard_by_age_year.csv` | age × year (`n_at_risk`, `n_exits`, `exit_hazard`) | `urps_exit_hazard_by_age_year()` |

## Run it

```sh
# in a producer environment with dplyr / tidyr / lubridate / readr:
export URPS_EVIDENCE_FILE=/path/to/normalized_provider_month_evidence.csv
export URPS_PROVIDER_AGE_FILE=/path/to/provider_birth_years.csv        # for the hazard
export URPS_RETIREMENT_SIGNAL_FILE=/path/to/explicit_retirement.csv    # optional (P4)
Rscript analysis/urps_exit_panel/build_exit_panel.R
# -> analysis/urps_exit_panel/urps_provider_month_activity.csv   (source of truth)
# -> analysis/urps_exit_panel/urps_observed_departures.csv
# -> analysis/urps_exit_panel/urps_exit_hazard_by_age_year.csv
```

It fails loud (never a fake panel) when the evidence file or age table is
missing, and re-validates the evidence union against the serving contract before
building.

## Activate the observed facts

The serving functions are **wired the same way as demand**: an option (then an
env var) points at a frozen artifact; unset → fail loud.

```r
options(mufflyaccess.urps_departures_path =
        "analysis/urps_exit_panel/urps_observed_departures.csv")
options(mufflyaccess.urps_exit_hazard_path =
        "analysis/urps_exit_panel/urps_exit_hazard_by_age_year.csv")

mufflyaccess::urps_departures()               # one row / confirmed exit
mufflyaccess::urps_exit_counts()              # annual n_retired + n_retired_with_evidence
mufflyaccess::urps_exit_hazard_by_age_year()  # age × year departure hazard
```

| option | env var |
|---|---|
| `mufflyaccess.urps_departures_path` | `MUFFLYACCESS_URPS_DEPARTURES` |
| `mufflyaccess.urps_exit_hazard_path` | `MUFFLYACCESS_URPS_EXIT_HAZARD` |

## Flip the manifest to observed

Once a real panel is frozen, set these on the isochrones **producer** manifest
(retirement re-derivation belongs there, not in mufflyaccess):

```
retirement_ascertainment    : "observed"
retirement_definition        : "observed_workforce_exit"
retirement_panel_resolution  : "provider_month"
exit_confirmation_months     : 12
```

Then `urps_retirement_status()` returns `"observed"`,
`urps_require_retirement_ascertained()` stops stopping, and `n_retired` carries
actual numbers across the count/projection contracts instead of `NA`.

## cliff follow-up (not in mufflyaccess)

cliff should **not** replace its Weibull retirement curve with these historical
counts — that would trade a smooth process for noisy point estimates. It should
estimate the departure **process** (with uncertainty) from the observed hazards:
`wc_project()` gains `retirement_source = c("observed_hazard", "legacy_modeled")`,
where `"observed_hazard"` calibrates the forward simulation to
`mufflyaccess::urps_exit_hazard_by_age_year()` and `"legacy_modeled"` keeps the
frozen 2016–2021 curve. mufflyaccess serves the observed *past*; cliff still
simulates the *future*, now anchored to it.
