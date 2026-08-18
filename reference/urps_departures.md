# Observed URPS workforce departures

Serves the frozen provider-level observed-departure artifact – one row
per confirmed departure from the practicing workforce (a first absent
month confirmed after the panel's ascertainment window). **Fail-loud by
default:** departures are unavailable until an observed artifact is
configured via `options(mufflyaccess.urps_departures_path = ...)` or
`MUFFLYACCESS_URPS_DEPARTURES`; otherwise this calls
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md),
which stops (an unascertained retirement is never served as zero
departures).

## Usage

``` r
urps_departures(start_year = NULL, end_year = NULL)
```

## Arguments

- start_year, end_year:

  Optional inclusive `exit_year` bounds.

## Value

A `data.frame`: `provider_id`, `exit_month`, `exit_year`, `exit_reason`
(`"workforce_exit"` / `"retired"`), `retirement_observed`.

## See also

[`urps_exit_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_counts.md),
[`urps_exit_hazard_by_age_year()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_hazard_by_age_year.md),
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md)

Other URPS exit panel:
[`urps_exit_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_counts.md),
[`urps_exit_hazard_by_age_year()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_hazard_by_age_year.md),
[`validate_urps_exit_evidence()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_exit_evidence.md)

## Examples

``` r
ex <- system.file("extdata", "urps_observed_departures_example.csv",
  package = "mufflyaccess"
)
old <- options(mufflyaccess.urps_departures_path = ex)
head(urps_departures())
#>   provider_id exit_month    exit_reason retirement_observed age_at_exit
#> 1  1000000001 2019-07-01 workforce_exit               FALSE          58
#> 2  1000000002 2019-11-01        retired                TRUE          67
#> 3  1000000003 2020-03-01 workforce_exit               FALSE          49
#> 4  1000000004 2020-09-01        retired                TRUE          71
#> 5  1000000005 2021-02-01 workforce_exit               FALSE          63
#> 6  1000000006 2021-08-01        retired                TRUE          69
#>   exit_year
#> 1      2019
#> 2      2019
#> 3      2020
#> 4      2020
#> 5      2021
#> 6      2021
head(urps_departures(start_year = 2022))
#>   provider_id exit_month    exit_reason retirement_observed age_at_exit
#> 1  1000000007 2022-01-01 workforce_exit               FALSE          55
#> 2  1000000008 2022-06-01        retired                TRUE          66
#> 3  1000000009 2023-04-01 workforce_exit               FALSE          60
#> 4  1000000010 2023-10-01        retired                TRUE          73
#>   exit_year
#> 1      2022
#> 2      2022
#> 3      2023
#> 4      2023
options(old)
```
