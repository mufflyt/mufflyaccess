# Read the ABOG certification registry refresh

Verifies the file's hash before reading, so a stale or partial copy
cannot enter an analysis unnoticed.

## Usage

``` r
read_abog_refresh(path = NULL)
```

## Arguments

- path:

  Optional explicit path; otherwise resolved as above.

## Value

A data frame of 79,398 registry rows.
