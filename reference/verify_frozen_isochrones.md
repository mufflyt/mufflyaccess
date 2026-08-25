# Verify a directory holds the frozen isochrone set

Hashes every band and compares against the manifest shipped with the
package.

## Usage

``` r
verify_frozen_isochrones(dir, quiet = FALSE)
```

## Arguments

- dir:

  Directory to check.

- quiet:

  Suppress the per-band report.

## Value

`TRUE` invisibly if every band matches; otherwise an error naming the
bands that differ.
