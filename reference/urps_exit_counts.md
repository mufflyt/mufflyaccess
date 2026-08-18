# Observed URPS workforce departures by year

Aggregates
[`urps_departures()`](https://mufflyt.github.io/mufflyaccess/reference/urps_departures.md)
to annual observed departure counts – the real numbers the
workforce-count series can finally carry instead of `NA`. The primary
event is **departure from the practicing workforce** (`n_departed`);
retirement is only one *observed reason* for it, so
`n_retired_with_evidence` (the `exit_reason == "retired"` subset) is the
count you should use when you specifically mean retirement. `n_retired`
is retained as a **backwards-compatible alias of `n_departed`** (equal
in value) for downstream contracts that still read that name; new code
should prefer `n_departed`.
`retirement_definition = "observed_workforce_exit"` records that this
counts departures from practice, not only self-declared retirements.

## Usage

``` r
urps_exit_counts(start_year = NULL, end_year = NULL)
```

## Arguments

- start_year, end_year:

  Optional inclusive `exit_year` bounds.

## Value

A `data.frame`: `year`, `n_departed` (all workforce exits), `n_retired`
(backwards-compatible alias of `n_departed`), `n_retired_with_evidence`
(the `exit_reason == "retired"` subset),
`retirement_status = "observed"`, `retirement_definition`.

## See also

[`urps_departures()`](https://mufflyt.github.io/mufflyaccess/reference/urps_departures.md),
[`urps_exit_hazard_by_age_year()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_hazard_by_age_year.md)

Other URPS exit panel:
[`urps_departures()`](https://mufflyt.github.io/mufflyaccess/reference/urps_departures.md),
[`urps_exit_hazard_by_age_year()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_hazard_by_age_year.md),
[`validate_urps_exit_evidence()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_exit_evidence.md)

## Examples

``` r
ex <- system.file("extdata", "urps_observed_departures_example.csv",
  package = "mufflyaccess"
)
old <- options(mufflyaccess.urps_departures_path = ex)
urps_exit_counts()
#>   year n_departed n_retired n_retired_with_evidence retirement_status
#> 1 2019          2         2                       1          observed
#> 2 2020          2         2                       1          observed
#> 3 2021          2         2                       1          observed
#> 4 2022          2         2                       1          observed
#> 5 2023          2         2                       1          observed
#>     retirement_definition
#> 1 observed_workforce_exit
#> 2 observed_workforce_exit
#> 3 observed_workforce_exit
#> 4 observed_workforce_exit
#> 5 observed_workforce_exit
options(old)
```
