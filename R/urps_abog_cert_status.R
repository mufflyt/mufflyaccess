# ==============================================================================
# URPS ABOG certification-status ascertainment.
#
# mufflyaccess serves OBSERVED facts (see urps_flows.R header). This is one:
# per-physician current-use ABOG certification status for the URPS/FPMRS
# board-certified cohort, as determined by isochrones'
# validate_abog_refresh_integrity() (R/validators/abog_refresh_integrity.R)
# against the 2026 ABOG re-scrape.
#
# Why this exists: a physician's raw certStatus after a coalescing refresh
# merge conflates two very different things -- actually re-scraped in 2026,
# vs. an old "Active"-looking status simply carried forward because the
# re-scrape never reached that physician. Trusting the merged certStatus at
# face value reads the second group as confirmed-current when it is not (46 of
# 1,282 URPS-boarded physicians in the 2026-08-22 snapshot). cert_category_current
# is the corrected classification; certStatus is the untouched raw ABOG text,
# kept for provenance -- neither is invented here, both are carried through
# verbatim from the validator's output.
#
# This is explicitly NOT a retirement model: cert_category_current values
# ("Active", "Retired", "Deceased", "Certification lapsed",
# "Unknown (stale active status)", "Unknown (no 2026 refresh data)", ...) are
# ABOG's own certification-status vocabulary, not a modeled workforce-exit
# estimate. Modeled retirement stays cliff's responsibility (urps_retirement.R).
# ==============================================================================

.URPS_ABOG_CERT_STATUS_FILE <- "urps_abog_cert_status.csv"

# NOT shipped in inst/extdata: this is a compiled per-physician roster and
# mufflyaccess is a public repo. Resolved from a local, non-repo location
# instead -- override with options(mufflyaccess.urps_abog_cert_status_path=)
# or the MUFFLYACCESS_URPS_ABOG_CERT_STATUS_PATH env var. Fails loudly rather
# than silently falling back to a stale or absent artifact.
.urps_abog_cert_status_path <- function() {
  opt <- getOption("mufflyaccess.urps_abog_cert_status_path", NULL)
  env <- Sys.getenv("MUFFLYACCESS_URPS_ABOG_CERT_STATUS_PATH", unset = NA)
  default <- path.expand(file.path(
    "~", "private-data", "mufflyaccess", .URPS_ABOG_CERT_STATUS_FILE
  ))
  p <- if (!is.null(opt)) opt else if (!is.na(env)) env else default
  if (!nzchar(p) || !file.exists(p))
    stop(sprintf(paste0(
      "[urps_abog_cert_status] artifact not found: %s.\n",
      "This is a compiled per-physician ABOG roster and is not distributed ",
      "with the public mufflyaccess package. Set ",
      "options(mufflyaccess.urps_abog_cert_status_path=) or the ",
      "MUFFLYACCESS_URPS_ABOG_CERT_STATUS_PATH env var to a local copy."
    ), p), call. = FALSE)
  p
}

#' Validated ABOG certification status for the URPS board-certified cohort
#'
#' @description Per-physician (`abog_id`-keyed) current-use ABOG certification
#'   status for the Female Pelvic Medicine & Reconstructive Surgery
#'   (URPS/FPMRS) board-certified cohort, frozen from isochrones'
#'   `validate_abog_refresh_integrity()` audit of the 2026 ABOG re-scrape.
#'
#' @details **Not distributed with this package.** This is a compiled
#'   per-physician roster and mufflyaccess is a public repository, so the data
#'   is NOT shipped in `inst/extdata` -- it is resolved from a local, non-repo
#'   path (`~/private-data/mufflyaccess/urps_abog_cert_status.csv` by default;
#'   override with `options(mufflyaccess.urps_abog_cert_status_path=)` or
#'   `MUFFLYACCESS_URPS_ABOG_CERT_STATUS_PATH`). Callers without a local copy
#'   get a clear error, never a silent empty result.
#'
#'   A raw, coalesced certStatus after a refresh merge does not
#'   distinguish a physician who was actually re-scraped in 2026 from one whose
#'   old "Active"-looking status was simply carried forward because the
#'   re-scrape never reached them. `cert_category_current` corrects for this:
#'   an "Active"-looking status is only reported as `"Active"` when
#'   `refresh_is_current` is `TRUE`; otherwise it is downgraded to
#'   `"Unknown (stale active status)"`. Time-limited certifications that have
#'   since lapsed are downgraded to `"Expired"`. Neither `certStatus` (ABOG's
#'   own raw text) nor `cert_category_current` (the corrected classification)
#'   is modeled or estimated -- both come straight from the source audit.
#'
#'   **Scope:** URPS/FPMRS board-certified cohort only (`subspecialty_name ==
#'   "Female Pelvic Medicine & Reconstructive Surgery"` in the ABOG roster),
#'   matching every other `urps_*` accessor in this package. GO/MIGS and the
#'   full ABOG-wide roster are out of scope here; see cliff's
#'   `data/abog_provider_dataframe_*.csv` for the unfiltered roster.
#'
#'   **This is not a retirement model.** `cert_category_current` is ABOG's own
#'   certification-status vocabulary (Active / Retired / Deceased /
#'   Certification lapsed / Unknown ...), observed directly from the source,
#'   not a modeled workforce-exit estimate. Modeled retirement is cliff's
#'   responsibility ([urps_retirement_hazard()]).
#'
#' @return A `data.frame`, one row per URPS-boarded physician, with columns:
#'   \itemize{
#'     \item `abog_id` -- integer, ABOG's own provider identifier (join key).
#'     \item `certStatus` -- character, ABOG's raw (coalesced) certification
#'       status text, unmodified.
#'     \item `cert_category_current` -- character, the corrected current-use
#'       classification (see Details).
#'     \item `refresh_is_current` -- logical, whether this physician's record
#'       was actually re-scraped in the 2026 refresh (`FALSE` = carried
#'       forward from the pre-2026 roster).
#'     \item `cert_status_is_expired` -- logical, whether a time-limited
#'       refreshed status has an explicit expiration date that has passed.
#'     \item `refresh_snapshot_date` -- character (ISO date), date of the
#'       source ABOG re-scrape this classification was computed from.
#'     \item `refresh_source_sha256` -- character, SHA-256 of the raw
#'       re-scrape file the classification was computed from.
#'     \item `method_version` -- character, version tag of the classifying
#'       validator.
#'   }
#' @seealso [urps_retirement_hazard()], [urps_retirement_status()]
#' @family URPS workforce
#' @examples
#' \dontrun{
#' # Requires a local copy -- not distributed with the package (see Details).
#' cs <- urps_abog_cert_status()
#' table(cs$cert_category_current)
#' # physicians whose "Active"-looking status is NOT confirmed by the 2026 refresh
#' subset(cs, cert_category_current == "Unknown (stale active status)")
#' }
#' @export
urps_abog_cert_status <- function() {
  d <- utils::read.csv(
    .urps_abog_cert_status_path(),
    stringsAsFactors = FALSE,
    colClasses = c(
      abog_id = "integer",
      certStatus = "character",
      cert_category_current = "character",
      refresh_is_current = "logical",
      cert_status_is_expired = "logical",
      refresh_snapshot_date = "character",
      refresh_source_sha256 = "character",
      method_version = "character"
    )
  )
  required <- c(
    "abog_id", "certStatus", "cert_category_current", "refresh_is_current",
    "cert_status_is_expired", "refresh_snapshot_date", "refresh_source_sha256",
    "method_version"
  )
  missing <- setdiff(required, names(d))
  if (length(missing))
    stop(sprintf(
      "[urps_abog_cert_status] frozen artifact is missing columns: %s.",
      paste(missing, collapse = ", ")
    ), call. = FALSE)
  if (anyDuplicated(d$abog_id))
    stop("[urps_abog_cert_status] frozen artifact has duplicate abog_id values.",
         call. = FALSE)
  d
}
