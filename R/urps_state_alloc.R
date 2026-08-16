#' @keywords internal
URPS_STATE_ALLOC_VERSION <- "0.1.0"

.URPS_STATE_FEMALE_POP_ACS2020 <- c(
  AL =  2481661L, AZ =  3682671L, AR =  1503453L, CA = 19433752L,
  CO =  2856726L, CT =  1813099L, DE =   489073L, DC =   373310L,
  FL = 11088025L, GA =  5577800L, ID =   908765L, IL =  6454777L,
  IN =  3327024L, IA =  1573083L, KS =  1455820L, KY =  2236461L,
  LA =  2347680L, ME =   685929L, MD =  3108481L, MA =  3502266L,
  MI =  5030451L, MN =  2827474L, MS =  1527750L, MO =  3112099L,
  MT =   527447L, NE =   975017L, NV =  1538685L, NH =   680416L,
  NJ =  4484892L, NM =  1035791L, NY = 10045399L, NC =  5282093L,
  ND =   379440L, OH =  5896462L, OK =  1973481L, OR =  2127609L,
  PA =  6618254L, RI =   541956L, SC =  2667755L, SD =   434226L,
  TN =  3446047L, TX = 14573001L, UT =  1590283L, VT =   317524L,
  VA =  4309975L, WA =  3751753L, WV =   895516L, WI =  2914474L,
  WY =   285491L
)

local({
  pop <- .URPS_STATE_FEMALE_POP_ACS2020
  abbr_match <- all(sort(names(pop)) == sort(CONUS_STATE_ABBR))
  stopifnot(
    "state alloc version must be semver" =
      grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", URPS_STATE_ALLOC_VERSION),
    "female pop must cover exactly the 49 CONUS states" =
      length(pop) == 49L && !anyDuplicated(names(pop)) && abbr_match,
    "female pop values must be positive" =
      all(pop > 0),
    "female pop total must equal ACS2020_CONUS_FEMALE_POP" =
      sum(pop) == ACS2020_CONUS_FEMALE_POP
  )
})

#' URPS geographic state allocation module version
#'
#' Semantic version of the URPS state allocation module. Version 0.1.0 is a
#' pre-data skeleton using population-weighted placeholder weights; it will be
#' replaced when ABOG state-level roster data are available.
#'
#' @format Character scalar.
#' @family urps geography
#' @examples
#' URPS_STATE_ALLOC_VERSION # "0.1.0"
#' @export
URPS_STATE_ALLOC_VERSION

#' ACS 2016-2020 CONUS female population by state
#'
#' Returns a data frame of contiguous-US female population by state derived
#' from ACS 2016-2020 5-year estimates, Table B01001_026. Rows are sorted by
#' state FIPS code.
#'
#' @return A \code{data.frame} with 49 rows and four columns:
#'   \describe{
#'     \item{state_abbr}{Character. Two-letter USPS state abbreviation.}
#'     \item{state_fips}{Character. Two-digit Census FIPS code, zero-padded.}
#'     \item{female_pop}{Integer. ACS 2016-2020 5-year female population count.}
#'     \item{female_share}{Double. State share of CONUS female population (sums to 1).}
#'   }
#'   Carries attribute \code{source = "ACS 2016-2020 5-year, Table B01001_026,
#'   CONUS female population."}.
#'
#' @source U.S. Census Bureau, American Community Survey 2016-2020 5-Year
#'   Estimates, Table B01001_026 (total female), contiguous U.S. (48 states +
#'   DC). \url{https://data.census.gov/table/ACSDT5Y2020.B01001}
#'
#' @family urps geography
#'
#' @examples
#' df <- urps_state_female_pop()
#' nrow(df) # 49
#' sum(df$female_pop) # 164690617
#' head(df)
#'
#' @export
urps_state_female_pop <- function() {
  pop <- .URPS_STATE_FEMALE_POP_ACS2020
  fips <- CONUS_STATE_FIPS[match(names(pop), CONUS_STATE_ABBR)]
  df <- data.frame(
    state_abbr = names(pop),
    state_fips = fips,
    female_pop = as.integer(pop),
    female_share = as.double(pop) / sum(pop),
    stringsAsFactors = FALSE
  )
  df <- df[order(df$state_fips), ]
  rownames(df) <- NULL
  attr(df, "source") <- "ACS 2016-2020 5-year, Table B01001_026, CONUS female population."
  df
}

#' URPS state allocation weights
#'
#' Returns a named numeric vector of allocation weights that sum to 1.0, one
#' element per CONUS state (49 states including DC). Weights are used to
#' distribute national provider counts to individual states.
#'
#' @param method Character scalar naming the weighting method. Currently only
#'   \code{"female_pop"} (ACS 2016-2020 5-year female population) is supported.
#'
#' @return Named numeric vector of length 49. Names are two-letter USPS state
#'   abbreviations. Values sum to 1.0.
#'
#' @family urps geography
#'
#' @examples
#' w <- urps_state_alloc_weights()
#' sum(w) # 1
#' length(w) # 49
#' w[["CA"]] # largest weight
#'
#' @export
urps_state_alloc_weights <- function(method = "female_pop") {
  if (!identical(method, "female_pop")) {
    stop(
      "[urps_state_alloc_weights] unknown method '", method,
      "'; must be 'female_pop'.",
      call. = FALSE
    )
  }
  pop <- .URPS_STATE_FEMALE_POP_ACS2020
  pop / sum(pop)
}

#' Allocate a national provider count to CONUS states
#'
#' Distributes an integer national count \code{n} across the 49 CONUS states
#' using population-based (or caller-supplied) allocation weights. Rounding is
#' handled by \code{round()} with any remainder patched onto the state carrying
#' the largest weight.
#'
#' @param n Positive integer scalar. The national count to distribute.
#' @param weights Named numeric vector of length 49, or \code{NULL}. If
#'   \code{NULL}, defaults to \code{urps_state_alloc_weights("female_pop")}.
#'   Names must match \code{CONUS_STATE_ABBR}; values must sum to 1.0 within
#'   tolerance \code{1e-6}.
#'
#' @return A \code{data.frame} with 49 rows and three columns:
#'   \describe{
#'     \item{state_abbr}{Character. Two-letter USPS state abbreviation.}
#'     \item{state_fips}{Character. Two-digit Census FIPS code, zero-padded.}
#'     \item{n_allocated}{Integer. Provider count allocated to each state.}
#'   }
#'   Rows are sorted by \code{state_fips}.
#'
#' @family urps geography
#'
#' @examples
#' result <- urps_allocate_national(1000)
#' sum(result$n_allocated) # 1000
#' head(result)
#'
#' @export
urps_allocate_national <- function(n, weights = NULL) {
  stopifnot(
    "[urps_allocate_national] n must be a positive integer scalar" =
      is.numeric(n) && length(n) == 1L && is.finite(n) && n > 0 && n == as.integer(n)
  )
  n <- as.integer(n)

  if (is.null(weights)) {
    weights <- urps_state_alloc_weights("female_pop")
  }

  stopifnot(
    "[urps_allocate_national] weights must be a named numeric vector of length 49" =
      is.numeric(weights) && length(weights) == 49L && !is.null(names(weights)),
    "[urps_allocate_national] weights must sum to approximately 1.0" =
      abs(sum(weights) - 1.0) <= 1e-6,
    "[urps_allocate_national] weight names must match CONUS_STATE_ABBR" =
      all(sort(names(weights)) == sort(CONUS_STATE_ABBR))
  )

  allocated <- round(weights * n)
  remainder <- n - sum(allocated)
  if (remainder != 0L) {
    patch_idx <- which.max(weights)
    allocated[patch_idx] <- allocated[patch_idx] + remainder
  }

  fips <- CONUS_STATE_FIPS[match(names(weights), CONUS_STATE_ABBR)]
  df <- data.frame(
    state_abbr = names(weights),
    state_fips = fips,
    n_allocated = as.integer(allocated),
    stringsAsFactors = FALSE
  )
  df <- df[order(df$state_fips), ]
  rownames(df) <- NULL
  df
}

#' URPS state entrant allocation shares (HWMM-style)
#'
#' Returns a named numeric vector of entrant allocation shares per CONUS state,
#' following the Health Workforce Microsimulation Model (HWMM) geographic
#' migration approach. Currently a placeholder identical to
#' \code{urps_state_alloc_weights(demand_proxy)}.
#'
#' @param demand_proxy Character scalar. Demand proxy method passed to
#'   \code{urps_state_alloc_weights()}. Currently only \code{"female_pop"} is
#'   supported.
#'
#' @return Named numeric vector of length 49. Names are two-letter USPS state
#'   abbreviations. Values sum to 1.0.
#'
#' @references IHS Markit HWMM v5.19.20, pp. 31-32 (geographic migration
#'   approach to new-entrant allocation).
#'
#' @family urps geography
#'
#' @examples
#' shares <- urps_state_entrant_shares()
#' sum(shares) # 1
#' shares[["TX"]] # Texas share
#'
#' @export
urps_state_entrant_shares <- function(demand_proxy = "female_pop") {
  # When state-level URPS demand projections are available, replace female_pop
  # weights with (state_retirement_count + state_demand_growth) / national_total
  # per HWMM geographic migration approach (IHS Markit HWMM v5.19.20, pp. 31-32).
  urps_state_alloc_weights(demand_proxy)
}
