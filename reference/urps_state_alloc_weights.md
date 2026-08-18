# URPS state allocation weights

Returns a named numeric vector of allocation weights that sum to 1.0,
one element per CONUS state (49 states including DC). Weights are used
to distribute national provider counts to individual states.

## Usage

``` r
urps_state_alloc_weights(method = "female_pop")
```

## Arguments

- method:

  Character scalar naming the weighting method. Currently only
  `"female_pop"` (ACS 2016-2020 5-year female population) is supported.

## Value

Named numeric vector of length 49. Names are two-letter USPS state
abbreviations. Values sum to 1.0.

## See also

Other urps geography:
[`urps_allocate_national()`](https://mufflyt.github.io/mufflyaccess/reference/urps_allocate_national.md),
[`urps_state_entrant_shares()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_entrant_shares.md),
[`urps_state_female_pop()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_female_pop.md)

## Examples

``` r
w <- urps_state_alloc_weights()
sum(w) # 1
#> [1] 1
length(w) # 49
#> [1] 49
w[["CA"]] # largest weight
#> [1] 0.1180016
```
