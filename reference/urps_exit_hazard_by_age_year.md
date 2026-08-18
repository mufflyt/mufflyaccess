# Observed URPS exit hazard by age and year

Serves the frozen empirical departure-hazard artifact –
`n_exits / n_at_risk` per age x year from the provider-month panel's
risk sets. This is what cliff estimates its forward departure process
from: *past* departures are observed here; cliff still *simulates*
future departures, but calibrated to these observed hazards rather than
the frozen 2016-2021 curve. Configure via
`options(mufflyaccess.urps_exit_hazard_path=...)` or
`MUFFLYACCESS_URPS_EXIT_HAZARD`; fail-loud when unset.

## Usage

``` r
urps_exit_hazard_by_age_year()
```

## Value

A `data.frame`: `age`, `year`, `n_at_risk`, `n_exits`, `exit_hazard` (in
\[0, 1\]), `hazard_source`.

## See also

[`urps_departures()`](https://mufflyt.github.io/mufflyaccess/reference/urps_departures.md),
[`urps_exit_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_counts.md)

Other URPS exit panel:
[`urps_departures()`](https://mufflyt.github.io/mufflyaccess/reference/urps_departures.md),
[`urps_exit_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_counts.md),
[`validate_urps_exit_evidence()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_exit_evidence.md)

## Examples

``` r
ex <- system.file("extdata", "urps_exit_hazard_by_age_year_example.csv",
  package = "mufflyaccess"
)
old <- options(mufflyaccess.urps_exit_hazard_path = ex)
head(urps_exit_hazard_by_age_year())
#>   age year n_at_risk n_exits exit_hazard                 hazard_source
#> 1  55 2021       120       2    0.016667 observed_provider_month_panel
#> 2  60 2021        90       3    0.033333 observed_provider_month_panel
#> 3  65 2021        70       4    0.057143 observed_provider_month_panel
#> 4  70 2021        40       5    0.125000 observed_provider_month_panel
#> 5  55 2022       124       1    0.008065 observed_provider_month_panel
#> 6  60 2022        94       2    0.021277 observed_provider_month_panel
options(old)
```
