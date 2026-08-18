# URPS state entrant allocation shares (HWMM-style)

Returns a named numeric vector of entrant allocation shares per CONUS
state, following the Health Workforce Microsimulation Model (HWMM)
geographic migration approach. Currently a placeholder identical to
`urps_state_alloc_weights(demand_proxy)`.

## Usage

``` r
urps_state_entrant_shares(demand_proxy = "female_pop")
```

## Arguments

- demand_proxy:

  Character scalar. Demand proxy method passed to
  [`urps_state_alloc_weights()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_alloc_weights.md).
  Currently only `"female_pop"` is supported.

## Value

Named numeric vector of length 49. Names are two-letter USPS state
abbreviations. Values sum to 1.0.

## References

IHS Markit HWMM v5.19.20, pp. 31-32 (geographic migration approach to
new-entrant allocation).

## See also

Other urps geography:
[`urps_allocate_national()`](https://mufflyt.github.io/mufflyaccess/reference/urps_allocate_national.md),
[`urps_state_alloc_weights()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_alloc_weights.md),
[`urps_state_female_pop()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_female_pop.md)

## Examples

``` r
shares <- urps_state_entrant_shares()
sum(shares) # 1
#> [1] 1
shares[["TX"]] # Texas share
#> [1] 0.08848714
```
