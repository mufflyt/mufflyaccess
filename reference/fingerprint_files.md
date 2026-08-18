# SHA-256 fingerprint of the producing source file(s)

Lets an artifact record which code produced it (the `code_fingerprint`
provenance field), so a cache is rejected when the generating logic
changes even if the inputs did not. Order-independent (paths are sorted)
and content- based.

## Usage

``` r
fingerprint_files(paths)
```

## Arguments

- paths:

  Character vector of file paths.

## Value

64-character hex digest over the (sorted) per-file digests, or
`NA_character_` if no path exists.

## Examples

``` r
if (FALSE) { # \dontrun{
fingerprint_files(c("R/foo.R", "R/bar.R"))
} # }
```
