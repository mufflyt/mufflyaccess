# Draw one perturbed parameter set for a bootstrap replicate

Samples one set of perturbation parameters from their marginal
distributions for a single parametric-bootstrap replicate. The returned
list is passed as the `param_draw` argument to the user-supplied
`project_fn` in
[`urps_projection_ci()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_ci.md).

## Usage

``` r
urps_ci_param_draw(retirement_sigma_sd = 0.51, entrant_cv = 0.077, seed = NULL)
```

## Arguments

- retirement_sigma_sd:

  Standard deviation of the retirement-curve shift in years. Default
  0.51 gives ±1 year at the 95% level (1.96 × 0.51 ≈ 1).

- entrant_cv:

  Coefficient of variation for the entrant scale factor. Default 0.077
  gives ±15% at the 95% level (1.96 × 0.077 ≈ 0.15).

- seed:

  Single integer RNG seed, or `NULL` (default) to use the current RNG
  state.

## Value

A named list with elements:

- retirement_sigma_sd:

  the `retirement_sigma_sd` argument, passed through for traceability

- retirement_shift:

  `rnorm(1, 0, retirement_sigma_sd)` — additive year shift applied to
  the retirement-curve mu

- entrant_scale:

  `rnorm(1, 1, entrant_cv)` — multiplicative scale applied to n_entrants

- lfp_intercept_shift:

  `rnorm(1, 0, 0.05)` — additive shift to the LFP logistic intercept

## See also

[`urps_projection_ci()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_ci.md),
[`urps_retirement_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_params.md),
[`urps_lfp_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_params.md)

Other URPS projection CI:
[`urps_projection_ci()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection_ci.md)

## Examples

``` r
urps_ci_param_draw(seed = 1L)
#> $retirement_sigma_sd
#> [1] 0.51
#> 
#> $retirement_shift
#> [1] -0.3194914
#> 
#> $entrant_scale
#> [1] 1.014141
#> 
#> $lfp_intercept_shift
#> [1] -0.04178143
#> 
# reproducible draw
a <- urps_ci_param_draw(seed = 42L)
b <- urps_ci_param_draw(seed = 42L)
identical(a, b) # TRUE
#> [1] TRUE
```
