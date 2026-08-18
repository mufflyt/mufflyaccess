# Full URPS labor force participation curve as a data.frame

Returns `P(active | age, sex)` over a specified age range as a
`data.frame(age, p_active)`. Convenience wrapper for cliff to tabulate
or plot the LFP curve for one sex.

## Usage

``` r
urps_lfp_curve(sex, age_range = 35:80)
```

## Arguments

- sex:

  `"female"` or `"male"` (length-1).

- age_range:

  Integer or numeric vector of ages (default `35:80`).

## Value

A `data.frame` with columns `age` (integer) and `p_active` (numeric, in
(0, 1)). One row per element of `age_range`.

## See also

[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md),
[`urps_lfp_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_params.md)

Other URPS LFP:
[`URPS_LFP_VERSION`](https://mufflyt.github.io/mufflyaccess/reference/URPS_LFP_VERSION.md),
[`urps_apply_lfp()`](https://mufflyt.github.io/mufflyaccess/reference/urps_apply_lfp.md),
[`urps_lfp_params()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lfp_params.md),
[`urps_p_active()`](https://mufflyt.github.io/mufflyaccess/reference/urps_p_active.md)

## Examples

``` r
head(urps_lfp_curve("female"))
#>   age  p_active
#> 1  35 0.9805103
#> 2  36 0.9787468
#> 3  37 0.9768277
#> 4  38 0.9747396
#> 5  39 0.9724687
#> 6  40 0.9700000
urps_lfp_curve("male", age_range = 40:70)
#>    age  p_active
#> 1   40 0.9800000
#> 2   41 0.9782368
#> 3   42 0.9763219
#> 4   43 0.9742430
#> 5   44 0.9719868
#> 6   45 0.9695391
#> 7   46 0.9668848
#> 8   47 0.9640079
#> 9   48 0.9608911
#> 10  49 0.9575163
#> 11  50 0.9538642
#> 12  51 0.9499147
#> 13  52 0.9456463
#> 14  53 0.9410367
#> 15  54 0.9360626
#> 16  55 0.9306998
#> 17  56 0.9249233
#> 18  57 0.9187073
#> 19  58 0.9120256
#> 20  59 0.9048516
#> 21  60 0.8971586
#> 22  61 0.8889200
#> 23  62 0.8801095
#> 24  63 0.8707018
#> 25  64 0.8606729
#> 26  65 0.8500000
#> 27  66 0.8386628
#> 28  67 0.8266435
#> 29  68 0.8139275
#> 30  69 0.8005038
#> 31  70 0.7863659
```
