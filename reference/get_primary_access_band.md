# Return the primary access band in the requested units.

Return the primary access band in the requested units.

## Usage

``` r
get_primary_access_band(units = c("min", "sec"))
```

## Arguments

- units:

  One of `"min"` (default) or `"sec"`.

## Value

Integer scalar –
[PRIMARY_ACCESS_BAND_MIN](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md)
(60) or
[PRIMARY_ACCESS_BAND_SEC](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_SEC.md)
(3600).

## See also

[`get_canonical_bands()`](https://mufflyt.github.io/mufflyaccess/reference/get_canonical_bands.md),
[PRIMARY_ACCESS_BAND_MIN](https://mufflyt.github.io/mufflyaccess/reference/PRIMARY_ACCESS_BAND_MIN.md)

Other access-band accessors:
[`get_canonical_bands()`](https://mufflyt.github.io/mufflyaccess/reference/get_canonical_bands.md)

## Examples

``` r
get_primary_access_band() # 60  (minutes)
#> [1] 60
get_primary_access_band("sec") # 3600 (seconds)
#> [1] 3600
```
