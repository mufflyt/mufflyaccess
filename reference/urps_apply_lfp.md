# Apply LFP to a certified cohort to obtain the practicing headcount

Multiplies `certified_n` by `urps_p_active(age, sex)` to produce
`practicing_n` — the expected number of providers actively practicing in
a given year conditional on still holding certification. This is the
first step of the supply pipeline before applying the FTE weight:

    cohort <- urps_apply_lfp(cohort)   # certified_n -> practicing_n
    fte    <- urps_effective_fte_sex(   # practicing_n -> supply_clinical_fte
                data.frame(..., n = cohort$practicing_n), scale)

Or call
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md)
to do both steps in one call.

## Usage

``` r
urps_apply_lfp(cohort)
```

## Arguments

- cohort:

  A `data.frame` with columns `age` (numeric/integer), `sex` (`"female"`
  / `"male"`), and `certified_n` (numeric). Other columns are passed
  through unchanged.

## Value

The same `data.frame` with a new column `practicing_n` =
`certified_n * urps_p_active(age, sex)`. Any existing `practicing_n`
column is overwritten.

## See also

[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md),
[`urps_supply_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_supply_fte_sex.md),
[`urps_effective_fte_sex()`](https://mufflyt.github.io/mufflyaccess/reference/urps_effective_fte_sex.md)

Other URPS LFP:
[`URPS_LFP_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_LFP_VERSION.md),
[`urps_lfp_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_curve.md),
[`urps_lfp_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_params.md),
[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md)

## Examples

``` r
cohort <- data.frame(
  age = c(45L, 62L, 45L, 62L),
  sex = c("female", "female", "male", "male"),
  pathway = c("ABOG", "ABOG", "ABU", "ABU"),
  certified_n = c(350, 150, 100, 40)
)
urps_apply_lfp(cohort)
#>   age    sex pathway certified_n practicing_n
#> 1  45 female    ABOG         350    333.93054
#> 2  62 female    ABOG         150    123.32109
#> 3  45   male     ABU         100     96.95391
#> 4  62   male     ABU          40     35.20438
```
