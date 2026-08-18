# Coordinate fitness for travel-time analysis

Not every coordinate is fit for every purpose. A city centroid is a
valid county or congressional-district locator and an invalid isochrone
origin: a drive-time polygon drawn from the middle of a city is a
polygon around a place nobody works. Geocode quality therefore has to
travel with the coordinates and be enforced at the point of use.

## Why it errors instead of filtering

Silently dropping unfit rows changes a denominator without anyone
noticing, which is the failure this guard exists to prevent. In the
midwifery workforce study the generalist population was once defined as
"whoever happened to be geocoded" – 28,512 of a 50,556-person roster –
and the missingness was invisible precisely because the missing were
never counted. A loud stop forces the caller to filter deliberately and
report the exclusion.

## See also

Other coordinate-fitness:
[`assert_travel_time_eligible()`](https://mufflyt.github.io/mufflyaccess/reference/assert_travel_time_eligible.md)

## Author

Tyler Muffly, MD + Claude Code
