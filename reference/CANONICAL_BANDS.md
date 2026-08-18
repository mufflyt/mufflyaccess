# Canonical drive-time contour bands (minutes)

The full set of drive-time thresholds the isochrone pipeline generates.
The primary/headline analysis band
([PRIMARY_ACCESS_BAND_MIN](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md))
must be a member.

## Usage

``` r
CANONICAL_BANDS
```

## Format

Integer vector, minutes, ascending.

## Source

isochrones/R/contour_bands.R (pipeline generation set)

## See also

[PRIMARY_ACCESS_BAND_MIN](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md)
(the headline member),
[`get_canonical_bands()`](https://mufflyt.github.io/mufflyaccess/reference/get_canonical_bands.md)

Other access-band constants:
[`PRIMARY_ACCESS_BAND_MIN`](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md),
[`PRIMARY_ACCESS_BAND_SEC`](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_SEC.md),
[`TRACT_REACHED_COVERAGE_PCT`](https://mufflyt.github.io/mufflyaccess/reference/TRACT_REACHED_COVERAGE_PCT.md)

## Examples

``` r
CANONICAL_BANDS # 30 60 120 180
#> [1]  30  60 120 180
PRIMARY_ACCESS_BAND_MIN %in% CANONICAL_BANDS # TRUE
#> [1] TRUE
```
