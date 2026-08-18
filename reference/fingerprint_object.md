# SHA-256 fingerprint of an in-memory R object

SHA-256 fingerprint of an in-memory R object

## Usage

``` r
fingerprint_object(x)
```

## Arguments

- x:

  Any R object.

## Value

64-character hex digest.

## Examples

``` r
fingerprint_object(list(a = 1, b = "x"))
#> [1] "98ab2dea3689ef3272b34e824c2d58bff0c08408cb82cb1bc91c616c75741577"
```
