# Literature-calibrated URPS retirement survival curve parameters

The logistic survival curve parameter table (mu, sigma) for the URPS
retirement model, stratified by sex and certification pathway. These are
the inputs to
[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md)
and
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md).

## Usage

``` r
urps_retirement_params()
```

## Value

A `data.frame` with columns `sex` (`"female"` or `"male"`),
`certification_pathway` (`"ABOG"` or `"ABU"`), `mu_years` (median
retirement age), `sigma_years` (spread), and `calibration_status`.
Carries attributes `source`, `formula`, and `curve_type`.

## Details

**Calibration status:** `"calibrated_from_literature"` — parameters are
derived from published physician retirement patterns (see the `source`
attribute) but are NOT estimated from ABOG-specific lapse or
recertification data. This status is intentionally explicit so consumers
and reviewers know these are placeholder-quality pending a URPS-specific
data source (ABOG certification panel or an ACOG workforce survey).

**Pathway vocabulary:** `certification_pathway` here is `"ABOG"` or
`"ABU"` — the per-individual pathway, NOT the three-value count-contract
vocabulary (`"ABOG"` / `"ABU_NET_NEW"` / `"ABOG_PLUS_ABU"`). The
retirement hazard applies to individual providers, not to aggregated
pathway cells.

## See also

[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_survival_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_survival_curve.md),
[URPS_RETIREMENT_CURVE_VERSION](https://mufflyt.github.io/mufflyaccess/reference/URPS_RETIREMENT_CURVE_VERSION.md)

Other URPS retirement curve:
[`URPS_RETIREMENT_CURVE_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_RETIREMENT_CURVE_VERSION.md),
[`urps_p_still_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_still_active.md),
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_survival_curve()`](https://mufflyt.github.io/mufflyaccess/reference/urps_survival_curve.md)

## Examples

``` r
urps_retirement_params()
#>      sex certification_pathway mu_years sigma_years         calibration_status
#> 1 female                  ABOG       65           4 calibrated_from_literature
#> 2   male                  ABOG       68           4 calibrated_from_literature
#> 3 female                   ABU       64           4 calibrated_from_literature
#> 4   male                   ABU       67           4 calibrated_from_literature
attr(urps_retirement_params(), "source")
#> [1] "IHS Markit HWMM v5.19.20 Exhibit 17 (physician retirement by age and sex); AAMC 2022 Physician Workforce Report Table 1.3; ACOG 2021 Workforce Survey (retirement age by sex); AMA 2022 Physician Practice Benchmark Survey. Sharpen with: ABOG lapse/recertification panel or URPS practice survey."
attr(urps_retirement_params(), "formula")
#> [1] "S(age; mu, sigma) = 1 / (1 + exp((age - mu) / sigma))"
```
