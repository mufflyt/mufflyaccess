# Primary (headline) access drive-time band, in MINUTES

The single drive-time threshold behind every headline access / coverage
/ "desert" statistic ("within 60 minutes of a subspecialist"). Distinct
from
[CANONICAL_BANDS](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md);
MUST be one of its members.

## Usage

``` r
PRIMARY_ACCESS_BAND_MIN
```

## Format

Integer scalar (minutes).

## See also

[PRIMARY_ACCESS_BAND_SEC](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_SEC.md)
(the derived seconds form),
[CANONICAL_BANDS](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md)

Other access-band constants:
[`CANONICAL_BANDS`](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md),
[`PRIMARY_ACCESS_BAND_SEC`](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_SEC.md),
[`TRACT_REACHED_COVERAGE_PCT`](https://mufflyt.github.io/mufflyaccess/reference/TRACT_REACHED_COVERAGE_PCT.md)

## Examples

``` r
PRIMARY_ACCESS_BAND_MIN # 60
#> [1] 60
```
