# Two-bracket Wu-2014 PFD prevalence for one condition

Two-bracket Wu-2014 PFD prevalence for one condition

## Usage

``` r
pfd_prevalence(condition = "any_PFD")
```

## Arguments

- condition:

  one of `WU2014_PFD_PREVALENCE$condition` (default "any_PFD").

## Value

named numeric `c(`65_79`=, `80plus`=)`.

## See also

[WU2014_PFD_PREVALENCE](https://mufflyt.github.io/mufflyaccess/reference/WU2014_PFD_PREVALENCE.md)
(the underlying table),
[`pfd_prevalence_acs_bands()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence_acs_bands.md)
(the same rates spread over ACS age-band columns).

Other pfd-prevalence:
[`WU2014_PFD_PREVALENCE`](https://mufflyt.github.io/mufflyaccess/reference/WU2014_PFD_PREVALENCE.md),
[`pfd_prevalence_acs_bands()`](https://mufflyt.github.io/mufflyaccess/reference/pfd_prevalence_acs_bands.md)

## Examples

``` r
pfd_prevalence() # any_PFD: c(`65_79` = 0.368, `80plus` = 0.497)
#>  65_79 80plus 
#>  0.368  0.497 
pfd_prevalence("UI") # urinary incontinence: c(`65_79` = 0.272, `80plus` = 0.382)
#>  65_79 80plus 
#>  0.272  0.382 
if (FALSE) { # \dontrun{
pfd_prevalence("nope") # errors: unknown condition
} # }
```
