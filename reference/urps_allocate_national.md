# Allocate a national provider count to CONUS states

Distributes an integer national count `n` across the 49 CONUS states
using population-based (or caller-supplied) allocation weights. Rounding
is handled by [`round()`](https://rdrr.io/r/base/Round.html) with any
remainder patched onto the state carrying the largest weight.

## Usage

``` r
urps_allocate_national(n, weights = NULL)
```

## Arguments

- n:

  Positive integer scalar. The national count to distribute.

- weights:

  Named numeric vector of length 49, or `NULL`. If `NULL`, defaults to
  `urps_state_alloc_weights("female_pop")`. Names must match
  `CONUS_STATE_ABBR`; values must sum to 1.0 within tolerance `1e-6`.

## Value

A `data.frame` with 49 rows and three columns:

- state_abbr:

  Character. Two-letter USPS state abbreviation.

- state_fips:

  Character. Two-digit Census FIPS code, zero-padded.

- n_allocated:

  Integer. Provider count allocated to each state.

Rows are sorted by `state_fips`.

## See also

Other urps geography:
[`urps_state_alloc_weights()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_alloc_weights.md),
[`urps_state_entrant_shares()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_entrant_shares.md),
[`urps_state_female_pop()`](https://mufflyt.github.io/mufflyaccess/reference/urps_state_female_pop.md)

## Examples

``` r
result <- urps_allocate_national(1000)
sum(result$n_allocated) # 1000
#> [1] 1000
head(result)
#>   state_abbr state_fips n_allocated
#> 1         AL         01          15
#> 2         AZ         04          22
#> 3         AR         05           9
#> 4         CA         06         120
#> 5         CO         08          17
#> 6         CT         09          11
```
