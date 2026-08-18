# Primary access band, in SECONDS (derived)

`PRIMARY_ACCESS_BAND_MIN * 60` – the `range` value (seconds) that
selects the primary band in the Step-4 access tables (`range == 3600`).
Derived; never set independently.

## Usage

``` r
PRIMARY_ACCESS_BAND_SEC
```

## Format

Integer scalar (seconds).

## See also

[PRIMARY_ACCESS_BAND_MIN](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md)
(the minutes form it derives from)

Other access-band constants:
[`CANONICAL_BANDS`](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md),
[`PRIMARY_ACCESS_BAND_MIN`](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md),
[`TRACT_REACHED_COVERAGE_PCT`](https://mufflyt.github.io/mufflyaccess/reference/TRACT_REACHED_COVERAGE_PCT.md)

## Examples

``` r
PRIMARY_ACCESS_BAND_SEC # 3600
#> [1] 3600
identical(PRIMARY_ACCESS_BAND_SEC, PRIMARY_ACCESS_BAND_MIN * 60L) # TRUE
#> [1] TRUE
```
