#' National contiguous-US 2020 ACS female population
#'
#' The published density denominator behind "1 subspecialist per ~N women"
#' claims. ACS 2016-2020 5-year, table B01001_026 (total female), contiguous US
#' (48 states + DC).
#' @format Integer scalar (persons).
#' @source Primary: U.S. Census Bureau, American Community Survey 2016-2020
#'   5-Year Estimates, Detailed Table B01001 "Sex by Age", variable B01001_026
#'   (total female), summed over the 48 contiguous states + DC.
#'   <https://data.census.gov/table/ACSDT5Y2020.B01001>. Promoted from
#'   isochrones/R/acs_national_female_pop.R.
#' @seealso [TOTAL_FEMALE_VAR] (the ACS variable code), [CONUS_STATE_FIPS] (the scope)
#' @family census denominators
#' @examples
#' as.integer(ACS2020_CONUS_FEMALE_POP) # 164690617
#' attr(ACS2020_CONUS_FEMALE_POP, "vintage") # "ACS 2016-2020 5-year"
#' @export
ACS2020_CONUS_FEMALE_POP <- structure(
  164690617L,
  vintage = "ACS 2016-2020 5-year",
  table   = "B01001_026 (total female)",
  scope   = "contiguous U.S. (48 states + DC)",
  units   = "persons (women)"
)

stopifnot(
  "ACS2020_CONUS_FEMALE_POP must be a single positive integer" =
    is.integer(ACS2020_CONUS_FEMALE_POP) && length(ACS2020_CONUS_FEMALE_POP) == 1L &&
      ACS2020_CONUS_FEMALE_POP > 0L,
  "ACS2020_CONUS_FEMALE_POP must be a plausible national female-pop magnitude (150-175M)" =
    ACS2020_CONUS_FEMALE_POP > 150e6 && ACS2020_CONUS_FEMALE_POP < 175e6
)
