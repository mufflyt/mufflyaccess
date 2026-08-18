# Refuse coordinates that are not fit for routing

Call at the top of any function that generates isochrones, computes
drive times, or otherwise treats a coordinate as a real practice
location.

## Usage

``` r
assert_travel_time_eligible(df, context = "travel-time analysis")
```

## Arguments

- df:

  `data.frame`/`tibble`/`sf`: rows to check. May carry
  `usable_for_travel_time` (logical) and/or `coord_source` (character).

- context:

  `character(1)`: label for the error message, e.g. the calling
  function. Default "travel-time analysis".

## Value

Invisibly `TRUE` when every row is fit; otherwise
[`stop()`](https://rdrr.io/r/base/stop.html)s with a count of the
offending rows and how to exclude them.

## Details

Two independent signals are checked, either of which is disqualifying:

- a logical `usable_for_travel_time` column that is `FALSE`, or `NA`;

- a `coord_source` value containing "centroid" (city, county or ZIP
  centroid geocodes).

A data frame carrying neither column passes, so this is safe to call on
inputs that predate the convention – it constrains what it can see and
does not invent a verdict about what it cannot.

## Unknown fitness is not eligible

`usable_for_travel_time` is a three-state contract, not a boolean:

- `TRUE` – eligible.

- `FALSE` – refused: the coordinate is known to be unfit.

- `NA` – refused, with a *distinct* message: fitness was never
  established.

`NA` is refused because "eligible unless proven otherwise" is the wrong
default for a guard protecting travel-time inference – an unverified
coordinate that silently passes is the failure this function exists to
prevent. It is refused *separately* from `FALSE` because "we never
checked this row" and "this row is known bad" are different facts, and a
caller reporting an exclusion needs to say which. Do not coerce `NA` to
`FALSE` upstream to satisfy this: that discards the provenance of never
having checked.

## See also

Other coordinate-fitness:
[`coordinate_fitness`](https://mufflyt.github.io/mufflyaccess/reference/coordinate_fitness.md)

## Examples

``` r
if (FALSE) { # \dontrun{
generate_isochrones <- function(points) {
  assert_travel_time_eligible(points, context = "generate_isochrones()")
  # ...
}

# Deliberate exclusion, which must then be reported:
routable <- subset(providers, !grepl("centroid", coord_source))
message(nrow(providers) - nrow(routable), " excluded: centroid geocodes")
} # }
```
