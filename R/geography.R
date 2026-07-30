#' Non-contiguous state/territory USPS codes (excluded from CONUS analyses)
#' @format Character vector of USPS codes.
#' @source Primary: U.S. Census Bureau ANSI (formerly FIPS 5-2) state/territory
#'   codes, <https://www.census.gov/library/reference/code-lists/ansi.html>.
#'   Promoted from isochrones/R/geographic_classification.R.
#' @seealso [NON_CONTIGUOUS_FIPS] (the FIPS form), [CONUS_STATE_ABBR] (the complement)
#' @family geography constants
#' @examples
#' NON_CONTIGUOUS_CODES  # "HI" "AK" "PR" "GU" "VI" "AS" "MP"
#' @export
NON_CONTIGUOUS_CODES <- c("HI", "AK", "PR", "GU", "VI", "AS", "MP")

#' Non-contiguous state/territory FIPS codes (excluded from CONUS analyses)
#' @format Character vector of 2-digit FIPS codes.
#' @source Primary: U.S. Census Bureau ANSI (formerly FIPS 5-2) state/territory
#'   codes, <https://www.census.gov/library/reference/code-lists/ansi.html>.
#'   Promoted from isochrones/R/geographic_classification.R.
#' @seealso [NON_CONTIGUOUS_CODES] (the USPS form), [CONUS_STATE_FIPS] (the complement)
#' @family geography constants
#' @examples
#' NON_CONTIGUOUS_FIPS               # "02" (AK) "15" (HI) "60" ... territories
#' # drop non-contiguous rows from a state-FIPS-keyed table:
#' # subset(tbl, !state_fips %in% NON_CONTIGUOUS_FIPS)
#' @export
NON_CONTIGUOUS_FIPS <- c("02", "15", "60", "66", "69", "72", "78")

#' Contiguous-US state FIPS codes (48 states + DC)
#' @format Character vector of 49 two-digit FIPS codes.
#' @source Primary: U.S. Census Bureau ANSI (formerly FIPS 5-2) state codes,
#'   <https://www.census.gov/library/reference/code-lists/ansi.html>.
#'   Promoted from isochrones/R/geographic_classification.R.
#' @seealso [CONUS_STATE_ABBR] (the derived USPS form), [NON_CONTIGUOUS_FIPS]
#' @family geography constants
#' @examples
#' length(CONUS_STATE_FIPS)          # 49 (48 states + DC)
#' "02" %in% CONUS_STATE_FIPS        # FALSE (Alaska is non-contiguous)
#' @export
CONUS_STATE_FIPS <- c(
  "01", "04", "05", "06", "08", "09", "10", "11", "12", "13",
  "16", "17", "18", "19", "20", "21", "22", "23", "24", "25",
  "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36",
  "37", "38", "39", "40", "41", "42", "44", "45", "46", "47", "48",
  "49", "50", "51", "53", "54", "55", "56"
)

# Internal 50-states-plus-DC FIPS -> USPS crosswalk (the canonical Census map).
# Source: U.S. Census Bureau ANSI/FIPS state codes
# <https://www.census.gov/library/reference/code-lists/ansi.html>.
.STATE_FIPS_TO_ABBR <- c(
  "01"="AL","02"="AK","04"="AZ","05"="AR","06"="CA","08"="CO","09"="CT",
  "10"="DE","11"="DC","12"="FL","13"="GA","15"="HI","16"="ID","17"="IL",
  "18"="IN","19"="IA","20"="KS","21"="KY","22"="LA","23"="ME","24"="MD",
  "25"="MA","26"="MI","27"="MN","28"="MS","29"="MO","30"="MT","31"="NE",
  "32"="NV","33"="NH","34"="NJ","35"="NM","36"="NY","37"="NC","38"="ND",
  "39"="OH","40"="OK","41"="OR","42"="PA","44"="RI","45"="SC","46"="SD",
  "47"="TN","48"="TX","49"="UT","50"="VT","51"="VA","53"="WA","54"="WV",
  "55"="WI","56"="WY"
)

#' Contiguous-US state USPS abbreviations (48 states + DC), DERIVED from FIPS
#'
#' The abbreviation representation of [CONUS_STATE_FIPS]. Derived through the
#' canonical FIPS->USPS crosswalk so the FIPS and abbreviation forms of "CONUS"
#' can never drift apart. Use this instead of re-deriving
#' `setdiff(c(state.abb, "DC"), c("AK", "HI"))` inline. NOTE: plain
#' `c(state.abb, "DC")` (all 50 + DC, includes AK/HI) is a different set -- a
#' state-validation vocabulary, NOT CONUS.
#' @format Character vector of 49 USPS codes.
#' @source Derived from [CONUS_STATE_FIPS] via the U.S. Census Bureau ANSI/FIPS
#'   crosswalk, <https://www.census.gov/library/reference/code-lists/ansi.html>.
#' @seealso [CONUS_STATE_FIPS] (the FIPS form it is derived from),
#'   [NON_CONTIGUOUS_CODES]
#' @family geography constants
#' @examples
#' length(CONUS_STATE_ABBR)              # 49
#' any(c("AK", "HI") %in% CONUS_STATE_ABBR)   # FALSE (excluded by construction)
#' @export
CONUS_STATE_ABBR <- unname(.STATE_FIPS_TO_ABBR[CONUS_STATE_FIPS])

# ---- fail-loud validation (runs at namespace load) --------------------------
stopifnot(
  "CONUS_STATE_FIPS must be 49 unique 2-char codes" =
    length(CONUS_STATE_FIPS) == 49L && !anyDuplicated(CONUS_STATE_FIPS) &&
    all(nchar(CONUS_STATE_FIPS) == 2L),
  "NON_CONTIGUOUS_FIPS must be 7 unique codes, disjoint from CONUS" =
    length(NON_CONTIGUOUS_FIPS) == 7L && !anyDuplicated(NON_CONTIGUOUS_FIPS) &&
    !any(NON_CONTIGUOUS_FIPS %in% CONUS_STATE_FIPS),
  "every CONUS FIPS must map to an abbreviation (no NA in the crosswalk)" =
    !anyNA(CONUS_STATE_ABBR),
  "CONUS_STATE_ABBR must be 49 unique codes and exclude AK/HI" =
    length(CONUS_STATE_ABBR) == 49L && !anyDuplicated(CONUS_STATE_ABBR) &&
    !any(c("AK", "HI") %in% CONUS_STATE_ABBR),
  "CONUS_STATE_ABBR must equal (state.abb + DC) minus AK/HI (cross-check)" =
    setequal(CONUS_STATE_ABBR, setdiff(c(datasets::state.abb, "DC"), c("AK", "HI")))
)
