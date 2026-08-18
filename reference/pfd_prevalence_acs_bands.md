# Wu-2014 PFD prevalence as a named vector over the ACS 65+ age-band columns

Wu-2014 PFD prevalence as a named vector over the ACS 65+ age-band
columns

## Usage

``` r
pfd_prevalence_acs_bands(condition = "any_PFD")
```

## Arguments

- condition:

  one of `WU2014_PFD_PREVALENCE$condition` (default "any_PFD").

## Value

named numeric over c(a65_66E, a67_69E, a70_74E, a75_79E, a80_84E,
a85pE).

## See also

[`pfd_prevalence()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence.md)
(the two-bracket form these bands expand).

Other pfd-prevalence:
[`WU2014_PFD_PREVALENCE`](https://mufflyt.github.io/mufflyaccess/reference/WU2014_PFD_PREVALENCE.md),
[`pfd_prevalence()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence.md)

## Examples

``` r
b <- pfd_prevalence_acs_bands() # any_PFD spread across the 6 ACS 65+ bands
b[["a65_66E"]] # 0.368  (65-79 bracket rate)
#> [1] 0.368
b[["a85pE"]] # 0.497  (>=80 bracket rate)
#> [1] 0.497
# the four 65-79 bands all carry the 65-79 rate; the two 80+ bands the 80+ rate:
unname(b) # c(0.368, 0.368, 0.368, 0.368, 0.497, 0.497)
#> [1] 0.368 0.368 0.368 0.368 0.497 0.497
```
