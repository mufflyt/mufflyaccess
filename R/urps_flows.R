# ==============================================================================
# Contract 3.0.0 corrective interface (mufflyaccess 0.7.1)
#
# mufflyaccess serves OBSERVED historical workforce facts plus EXPLICIT
# missingness. It never manufactures retirement estimates or future entrants
# (that is cliff's modeling domain). Two corrections live here:
#
#  1. Retirement is NOT ascertained in the historical stock. The artifact ships
#     n_retired = 0 as a PLACEHOLDER (the pre-2023 series is a survivorship-biased
#     certification build-up; "a true entries-and-exits panel is delegated to
#     cliff" -- artifact manifest known_limitations). A placeholder 0 must never
#     enter a workforce model as a real count, so the public readers serve it as
#     NA_integer_ with an explicit retirement_status, and a guard fails loudly if
#     a consumer would treat unavailable retirement as zero.
#
#  2. Entrants are derived from urps_subspecialty_cert_year and represent ENTRY
#     INTO THE BOARD-CERTIFIED URPS STOCK -- NOT fellowship graduation year, NOT
#     first year of clinical practice, and NOT net workforce growth.
# ==============================================================================

.urps_retirement_statuses <- c("observed", "partially_observed", "not_ascertained")

#' Retirement/departure ascertainment status of the active URPS artifact
#'
#' @description mufflyaccess exposes retirement only when the artifact actually
#'   observes it. Reads an explicit `retirement_ascertainment` manifest field when
#'   present (forward-compatible); otherwise contract 3.x historical stock is a
#'   survivorship-biased certification build-up with retirement **not ascertained**
#'   (see the artifact manifest `known_limitations`). `"modeled"` is deliberately
#'   NOT a valid value here: modeled retirement belongs in cliff, never in
#'   mufflyaccess.
#' @return One of `"observed"`, `"partially_observed"`, `"not_ascertained"`.
#' @seealso [urps_require_retirement_ascertained()], [urps_counts_long()]
#' @family URPS workforce
#' @examples
#' # Ascertainment status of the served artifact (the bootstrap does not
#' # observe retirement, so this is "not_ascertained"):
#' urps_retirement_status()
#' @export
urps_retirement_status <- function() {
  m <- .urps_manifest()
  st <- m$retirement_ascertainment %||% m$retirement_status %||% "not_ascertained"
  st <- tolower(trimws(as.character(st)[1]))
  if (identical(st, "modeled")) {
    stop("[urps_retirement_status] artifact declares retirement 'modeled'; mufflyaccess ",
      "serves only observed facts. Modeled retirement belongs in cliff.",
      call. = FALSE
    )
  }
  if (!st %in% .urps_retirement_statuses) {
    stop(sprintf(
      "[urps_retirement_status] unknown retirement status '%s'; expected one of %s.",
      st, paste(.urps_retirement_statuses, collapse = ", ")
    ), call. = FALSE)
  }
  st
}

#' Require observed retirement before using a retirement/departure count
#'
#' @description Fail-loud guard for consumers (cliff): retirement is only a usable
#'   number when it is `"observed"`. Otherwise this stops, so an unascertained
#'   retirement can **never** be silently interpreted as zero departures. Call this
#'   before any `baseline - retirements` arithmetic.
#' @param what Label for the quantity, used in the error message.
#' @return Invisibly `TRUE` when retirement is observed; otherwise `stop()`s.
#' @seealso [urps_retirement_status()]
#' @family URPS workforce
#' @examples
#' # The guard stops unless retirement is observed, so a consumer can never
#' # read "unknown retirement" as zero departures:
#' tryCatch(urps_require_retirement_ascertained(),
#'   error = function(e) conditionMessage(e)
#' )
#' @export
urps_require_retirement_ascertained <- function(what = "retirement/departure counts") {
  st <- urps_retirement_status()
  if (identical(st, "observed")) {
    return(invisible(TRUE))
  }
  cv <- .urps_effective_contract_version(.urps_manifest(), .urps_contract())
  stop(sprintf(
    paste0(
      "[mufflyaccess] %s are '%s' in contract %s: n_retired is served as NA, ",
      "never 0. Observed historical departures are unavailable; modeled ",
      "retirement/departure is cliff's responsibility. Do NOT substitute 0."
    ),
    what, st, cv
  ), call. = FALSE)
}

# Internal guard: an unavailable count must never be presented as a concrete
# number (e.g. a placeholder 0). Used by validate_urps_artifact and testable.
.urps_guard_no_placeholder <- function(value, status, label = "retirement") {
  if (!identical(status, "observed") && length(value) && any(!is.na(value))) {
    stop(
      sprintf(
        paste0(
          "[mufflyaccess] %s is '%s' but a concrete count (%s) was supplied; ",
          "an unavailable count must remain NA, never 0."
        ),
        label, status, paste(utils::head(value[!is.na(value)], 3), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Entry into the board-certified URPS stock, by year and pathway
#'
#' @description Year-over-year additions to the active board-certified URPS stock,
#'   derived from `urps_subspecialty_cert_year` (the column `n_active` is keyed on).
#'   These are **entry into the board-certified URPS stock**, and are explicitly
#'   NOT:
#'   \itemize{
#'     \item fellowship graduation year;
#'     \item first year of clinical practice;
#'     \item net workforce growth (there is no attrition term -- see below).
#'   }
#'   While exits are `not_ascertained` (the current contract) these equal gross
#'   entrants; if a future artifact ascertains exits, this becomes net-of-exits and
#'   callers should switch to a provider-level entry count. The first year of the
#'   series is a **founding bucket**: all entries on or before that year (the
#'   build-up cannot separate pre-window certifications from that year alone);
#'   subsequent years are single-year entries.
#' @param measure `"board_certified_active"` (default) or `"roster_snapshot"`.
#' @param geography `"national"` (default) or `"conus"`.
#' @return A `data.frame`: `year`, `measure`, `geography`, `abog_entrants`,
#'   `abu_entrants`, `combined_entrants`, `basis`, `interpretation`,
#'   `first_year_is_founding_bucket`.
#' @seealso [urps_entrants()], [urps_counts()]
#' @family URPS workforce
#' @examples
#' # Entry into the certified stock by year and pathway.
#' # The first row is the founding bucket (all entries through that year).
#' head(urps_entry_counts())
#' @export
urps_entry_counts <- function(measure = "board_certified_active", geography = "national") {
  w <- urps_counts(measure = measure, geography = geography)
  w <- w[order(w$year), , drop = FALSE]
  diff_entry <- function(x) {
    e <- x - c(NA_integer_, utils::head(x, -1L))
    e[1] <- x[1] # founding bucket = entries through year 1
    as.integer(e)
  }
  data.frame(
    year = w$year,
    measure = w$measure[1],
    geography = w$geography[1],
    abog_entrants = diff_entry(w$abog_active),
    abu_entrants = diff_entry(w$abu_net_new),
    combined_entrants = diff_entry(w$combined_active),
    basis = "urps_subspecialty_cert_year",
    interpretation = "entry into the board-certified URPS stock (NOT fellowship graduation / first clinical year / net workforce growth)",
    first_year_is_founding_bucket = c(TRUE, rep(FALSE, nrow(w) - 1L)),
    stringsAsFactors = FALSE
  )
}

#' Board-certified URPS entrants for a single year
#'
#' @inheritParams urps_count
#' @return Integer count of entrants into the board-certified URPS stock in `year`
#'   (`include_urology = FALSE` = ABOG pathway; `TRUE` = ABOG + ABU). See
#'   [urps_entry_counts()] for the full definition and caveats.
#' @seealso [urps_entry_counts()]
#' @family URPS workforce
#' @examples
#' urps_entrants(2019) # ABOG pathway
#' urps_entrants(2019, include_urology = TRUE) # ABOG + ABU
#' @export
urps_entrants <- function(year, geography = "national", include_urology = FALSE,
                          measure = "board_certified_active") {
  ec <- urps_entry_counts(measure = measure, geography = geography)
  row <- ec[ec$year == as.integer(year), , drop = FALSE]
  if (!nrow(row)) {
    stop(sprintf(
      "[urps_entrants] no entry count for year %s (available: %s).",
      year, paste(ec$year, collapse = ", ")
    ), call. = FALSE)
  }
  as.integer(if (isTRUE(include_urology)) row$combined_entrants else row$abog_entrants)
}
