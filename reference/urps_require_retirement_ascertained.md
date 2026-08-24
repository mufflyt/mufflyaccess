# Require observed retirement before using a retirement/departure count

Fail-loud guard for consumers (cliff): retirement is only a usable
number when it is `"observed"`. Otherwise this stops, so an
unascertained retirement can **never** be silently interpreted as zero
departures. Call this before any `baseline - retirements` arithmetic.

## Usage

``` r
urps_require_retirement_ascertained(what = "retirement/departure counts")
```

## Arguments

- what:

  Label for the quantity, used in the error message.

## Value

Invisibly `TRUE` when retirement is observed; otherwise
[`stop()`](https://rdrr.io/r/base/stop.html)s.

## See also

[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md)

Other URPS workforce:
[`compare_urps_artifacts()`](https://mufflyt.github.io/mufflyaccess/reference/compare_urps_artifacts.md),
[`urps_abog_cert_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_abog_cert_status.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts.md),
[`urps_counts_long()`](https://mufflyt.github.io/mufflyaccess/reference/urps_counts_long.md),
[`urps_entrants()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entrants.md),
[`urps_entry_counts()`](https://mufflyt.github.io/mufflyaccess/reference/urps_entry_counts.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md),
[`urps_provenance()`](https://mufflyt.github.io/mufflyaccess/reference/urps_provenance.md),
[`urps_retired_values()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retired_values.md),
[`urps_retirement_status()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_status.md),
[`use_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/use_urps_artifact.md),
[`validate_urps_artifact()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_artifact.md),
[`validate_urps_ssot()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_ssot.md)

## Examples

``` r
# The guard stops unless retirement is observed, so a consumer can never
# read "unknown retirement" as zero departures:
tryCatch(urps_require_retirement_ascertained(),
  error = function(e) conditionMessage(e)
)
#> [1] "[mufflyaccess] retirement/departure counts are 'not_ascertained' in contract 3.0.0: n_retired is served as NA, never 0. Observed historical departures are unavailable; modeled retirement/departure is cliff's responsibility. Do NOT substitute 0."
```
