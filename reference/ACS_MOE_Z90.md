# ACS margin-of-error z multipliers and the 90-\>95 conversion factor

ACS publishes margins of error at the 90% confidence level:
`MOE_90 = ACS_MOE_Z90 * SE`. The Census-documented rounded multiplier is
**1.645** – do NOT substitute `qnorm(0.95)` (= 1.6449); the rounded
value is the published convention and changing it would move every
derived SE/CI. A 95% CI half-width = `MOE_90 * MOE90_TO_CI95_FACTOR`.
Reference these constants rather than re-deriving `1.96 / 1.645` inline.

## Usage

``` r
ACS_MOE_Z90

CI_Z95

MOE90_TO_CI95_FACTOR
```

## Format

numeric scalars. `MOE90_TO_CI95_FACTOR` is derived
(`CI_Z95/ACS_MOE_Z90`, ~1.1915).

## Source

Primary: U.S. Census Bureau, "Understanding and Using American Community
Survey Data: What All Data Users Need to Know" (margin-of-error
appendix; the 90% MOE multiplier is the published 1.645),
<https://www.census.gov/programs-surveys/acs/library/handbooks/general.html>.
Promoted from isochrones/R/moe_propagation.R.

## See also

[`mc_weighted_ci()`](https://mufflyt.github.io/mufflyaccess/reference/mc_weighted_ci.md),
which divides an ACS margin of error by `ACS_MOE_Z90` to recover the
standard error it resamples.

## Examples

``` r
ACS_MOE_Z90 # 1.645
#> [1] 1.645
moe_90 <- 500
se <- moe_90 / ACS_MOE_Z90 # ACS MOE -> standard error
ci95_halfwidth <- moe_90 * MOE90_TO_CI95_FACTOR
```
