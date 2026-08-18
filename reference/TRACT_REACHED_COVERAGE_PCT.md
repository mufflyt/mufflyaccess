# Tract "reached"/"covered" population-coverage threshold (percent)

A census tract counts as REACHED by a subspecialty at a drive-time band
when at least this percent of its (female) population lies within the
isochrone – a majority of tract women. `reached == 0` (below this) AND
rural defines a subspecialty access desert. This is the binary coverage
cut for desert counts, the exclusive-access contrast, and the logistic
"reached" outcome.

## Usage

``` r
TRACT_REACHED_COVERAGE_PCT
```

## Format

Integer scalar, percent in (0, 100\].

## Source

isochrones/R/access_thresholds.R; Ryerson 2022 two-vector desert def.

## See also

[PRIMARY_ACCESS_BAND_MIN](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md)
(the band a tract is "reached" within)

Other access-band constants:
[`CANONICAL_BANDS`](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md),
[`PRIMARY_ACCESS_BAND_MIN`](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md),
[`PRIMARY_ACCESS_BAND_SEC`](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_SEC.md)

## Examples

``` r
TRACT_REACHED_COVERAGE_PCT # 50
#> [1] 50
# a tract counts as reached when >= this percent of its women are in-band:
# tract$reached <- tract$pct_female_in_band >= TRACT_REACHED_COVERAGE_PCT
```
