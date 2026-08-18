# Validate a URPS projection table against the contract (fail loud)

Checks that a cliff-produced projection table conforms to the projection
contract, failing loud with a specific message on the first violation.
Verifies far more than column presence: every `scenario_id` is
registered in
[`urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/urps_scenarios.md),
the `baseline` scenario is present, the `certification_pathway` /
`geography_type` values are the count-contract vocabularies, there are
no duplicate series keys, the 95% bounds bracket the point estimate,
counts are non-negative, and `net_change` reconciles as
`entrants - exits`. Optionally ties the baseline-year starting stock
back to
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
so a projection can never start from a number the SSOT does not serve.

## Usage

``` r
validate_urps_projection(x, baseline_tie = NULL, tol = 1e-06)
```

## Arguments

- x:

  A projection `data.frame`, or a path to a CSV to read
  ([`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md)
  is used).

- baseline_tie:

  Optional named list pinning the starting stock to the served count:
  `list(year=, measure=, geography_type=, certification_pathway=)`. The
  pathway must be `"ABOG"` or `"ABOG_PLUS_ABU"` (the two
  [`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
  exposes).

- tol:

  Numeric tolerance for the `net_change == entrants - exits` identity
  (default `1e-6`).

## Value

Invisibly `TRUE`; otherwise stops with the failed check.

## Details

Checks performed, each failing loud:

- all required (non-optional) columns present;

- `scenario_id` values all registered
  ([`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md))
  and the `baseline` scenario present;

- `certification_pathway` in ABOG / ABU_NET_NEW / ABOG_PLUS_ABU and
  `geography_type` in national / conus;

- no duplicate
  `(year, scenario_id, specialty, certification_pathway, geography_type, geography_id)`
  key;

- `supply_headcount` non-negative; where present, `entrants` / `exits`
  non-negative and `lower_95 <= supply_headcount <= upper_95`;

- where present, `0 <= supply_clinical_fte <= supply_headcount` (a head
  is at most 1.0 clinical FTE);

- where all three are present, `net_change == entrants - exits` (within
  `tol`);

- with `baseline_tie`, the `baseline`-scenario `supply_headcount` at the
  named year/geography/pathway equals
  [`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
  for the matching measure.

## See also

[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md),
[`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md),
[`validate_urps_scenarios()`](https://mufflyt.github.io/mufflyaccess/reference/validate_urps_scenarios.md),
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)

Other URPS projection:
[`URPS_PROJECTION_CONTRACT_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_PROJECTION_CONTRACT_VERSION.md),
[`read_urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/read_urps_projection.md),
[`urps_gap_fte()`](https://mufflyt.github.io/mufflyaccess/reference/urps_gap_fte.md),
[`urps_projection_schema()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_schema.md)

## Examples

``` r
p <- read_urps_projection(system.file(
  "extdata", "urps_projection_example.csv",
  package = "mufflyaccess"
))
validate_urps_projection(p)
# tie the 2025 baseline stock to the served roster snapshot (1339):
validate_urps_projection(p, baseline_tie = list(
  year = 2025, measure = "roster_snapshot",
  geography_type = "national", certification_pathway = "ABOG_PLUS_ABU"
))
```
