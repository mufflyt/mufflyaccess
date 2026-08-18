# Return the canonical generation bands (minutes).

Return the canonical generation bands (minutes).

## Usage

``` r
get_canonical_bands()
```

## Value

[CANONICAL_BANDS](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md)
– the integer vector `c(30, 60, 120, 180)`.

## See also

[`get_primary_access_band()`](https://mufflyt.github.io/mufflyaccess/reference/get_primary_access_band.md),
[CANONICAL_BANDS](https://mufflyt.github.io/mufflyaccess/reference/CANONICAL_BANDS.md)

Other access-band accessors:
[`get_primary_access_band()`](https://mufflyt.github.io/mufflyaccess/reference/get_primary_access_band.md)

## Examples

``` r
get_canonical_bands() # 30 60 120 180
#> [1]  30  60 120 180
```
