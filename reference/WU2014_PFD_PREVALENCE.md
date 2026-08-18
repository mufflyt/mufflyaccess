# Wu 2014 age-specific symptomatic pelvic-floor-disorder (PFD) prevalence, women 65+

The demand denominator behind the relative-availability /
need-based-adequacy / condition-demand access numbers. `any_PFD` is the
primary denominator; `UI`/`FI`/`POP` are the condition-specific
variants.

SCOPE: this is the 65+ ACCESS denominator (Wu 2014). It is DISTINCT from
the workforce-cliff supply/demand line, which uses a full-age-curve
Nygaard-2008 table for a population projection – a different
cohort/source that is intentionally NOT this object and stays in the
cliff repo. Do not conflate.

## Usage

``` r
WU2014_PFD_PREVALENCE
```

## Format

`data.frame` (condition x p_65_79 / p_80plus), proportions.

## Source

Primary: Wu JM, Vaughan CP, Goode PS, et al. "Prevalence and trends of
symptomatic pelvic floor disorders in U.S. women." Obstet Gynecol
2014;123(1):141-148, Table 1. PMID 24463674;
doi:10.1097/AOG.0000000000000057 (estimates derived from NHANES
2005-2010). Promoted from isochrones/R/pfd_prevalence.R.

## See also

[`pfd_prevalence()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence.md)
and
[`pfd_prevalence_acs_bands()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence_acs_bands.md),
the accessors.

Other pfd-prevalence:
[`pfd_prevalence()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence.md),
[`pfd_prevalence_acs_bands()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence_acs_bands.md)

## Examples

``` r
WU2014_PFD_PREVALENCE
#>   condition p_65_79 p_80plus
#> 1   any_PFD   0.368    0.497
#> 2        UI   0.272    0.382
#> 3        FI   0.154    0.210
#> 4       POP   0.047    0.040
attr(WU2014_PFD_PREVALENCE, "source")
#> [1] "Wu JM et al. Obstet Gynecol 2014;123(1):141-148, Table 1 (PMID 24463674; doi:10.1097/AOG.0000000000000057; NHANES 2005-2010)"
```
