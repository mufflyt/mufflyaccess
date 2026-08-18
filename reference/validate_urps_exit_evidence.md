# Validate a normalized URPS provider-month evidence table

The tiny contract every source system (Medicare, NPPES, board roster,
Physician Compare, mystery-call) must normalize into before the exit
panel is built: one row per `provider_id` x `month` x `source`, with a
logical `practice_evidence`. Fail-loud so a malformed source can never
silently weaken ascertainment.

## Usage

``` r
validate_urps_exit_evidence(evidence)
```

## Arguments

- evidence:

  A `data.frame` with columns `provider_id`, `month`, `source`,
  `practice_evidence`.

## Value

Invisibly `TRUE` when valid; otherwise an error naming the problem.

## See also

[`urps_departures()`](https://mufflyt.github.io/mufflyaccess/reference/urps_departures.md),
[`urps_require_retirement_ascertained()`](https://mufflyt.github.io/mufflyaccess/reference/urps_require_retirement_ascertained.md)

Other URPS exit panel:
[`urps_departures()`](https://mufflyt.github.io/mufflyaccess/reference/urps_departures.md),
[`urps_exit_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_counts.md),
[`urps_exit_hazard_by_age_year()`](https://mufflyt.github.io/mufflyaccess/reference/urps_exit_hazard_by_age_year.md)

## Examples

``` r
ev <- data.frame(
  provider_id = "1234567890", month = as.Date("2023-01-01"),
  source = "nppes", practice_evidence = TRUE
)
validate_urps_exit_evidence(ev)
```
