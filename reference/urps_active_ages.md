# The URPS active-age distribution

Age distribution of the active urogynecology cohort, served from the
bundled artifact so no consumer has to carry its own copy. This is the
input an age-structured projection starts from; pair it with
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md)
to run one.

## Usage

``` r
urps_active_ages(
  pathway = "ABOG_PLUS_ABU",
  geography = "national",
  as = c("counts", "vector")
)
```

## Arguments

- pathway:

  Board pathway: `"ABOG_PLUS_ABU"` (default), `"ABOG"`, or
  `"ABU_NET_NEW"`. Case-insensitive.

- geography:

  `"national"` (default) or `"conus"`.

- as:

  `"counts"` (default) for one row per age, or `"vector"` for the
  distribution expanded to one element per provider – the form a
  microsimulation consumes directly.

## Value

With `as = "counts"`, a `data.frame` with columns `age` (integer) and
`n_active` (integer), ordered by age. With `as = "vector"`, an integer
vector of length equal to the active count.

## Details

The stored artifact holds the two base pathways (`ABOG`, `ABU_NET_NEW`)
for each geography. `ABOG_PLUS_ABU` is summed on read rather than
stored, so a combined total cannot disagree with its parts.

The result is checked against
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
on every call: the ages must total the published active count for the
same pathway and geography. A distribution that does not add up to the
count the package serves is a contradiction, and it fails loud rather
than returning a plausible number.

## See also

[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
for the totals these must reconcile to,
[`urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection.md)
for the canonical projection built from them,
[`urps_retirement_hazard()`](https://mufflyt.github.io/mufflyaccess/reference/urps_retirement_hazard.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md).

Other URPS SSOT:
[`urps_projection()`](https://mufflyt.github.io/mufflyaccess/reference/urps_projection.md)

## Examples

``` r
head(urps_active_ages())
#>   age n_active
#> 1  34        2
#> 2  35       21
#> 3  36       20
#> 4  37       53
#> 5  38       31
#> 6  39       61
length(urps_active_ages(as = "vector"))     # == urps_count(2023, "board_certified_active",
#> [1] 1306
#                                                "national", include_urology = TRUE)
head(urps_active_ages("ABOG", "conus"))
#>   age n_active
#> 1  34        2
#> 2  35       10
#> 3  36        8
#> 4  37       44
#> 5  38       24
#> 6  39       47
```
