# ==============================================================================
# The published URPS workforce SSOT interface (see ARCHITECTURE.md).
# isochrones builds + hashes the roster; mufflyaccess reads/validates/serves it;
# consumers call these functions and never derive a national URPS count.
#
# By default mufflyaccess serves a bundled BOOTSTRAP artifact
# (inst/extdata/urps_{counts_by_year.csv,manifest.json}). Point it at a released
# isochrones artifact directory with use_urps_artifact("<dir>") (or the
# `mufflyaccess.urps_artifact_dir` option / MUFFLYACCESS_URPS_ARTIFACT_DIR env
# var); the external artifact is validated before it is used.
# ==============================================================================

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# resolve the active artifact directory: option -> env var -> bundled extdata
.urps_artifact_dir <- function() {
  d <- getOption("mufflyaccess.urps_artifact_dir",
                 Sys.getenv("MUFFLYACCESS_URPS_ARTIFACT_DIR", ""))
  if (!is.null(d) && nzchar(d)) return(d)
  system.file("extdata", package = "mufflyaccess")
}

.urps_path <- function(file) {
  p <- file.path(.urps_artifact_dir(), file)
  if (!file.exists(p)) {                                   # dev (load_all) fallback
    alt <- file.path("inst", "extdata", file)
    if (file.exists(alt)) return(alt)
  }
  p
}

.urps_read_long <- function() {
  utils::read.csv(
    .urps_path("urps_counts_by_year.csv"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"),
    colClasses = c(year = "integer", board_pathway = "character",
                   n_active = "integer", n_ever_certified = "integer",
                   n_retired = "integer", snapshot_date = "character",
                   source_sha256 = "character", method_version = "character"))
}

.urps_manifest <- function() {
  jsonlite::fromJSON(.urps_path("urps_manifest.json"), simplifyVector = TRUE)
}

.urps_wide <- function() {
  d <- .urps_read_long()
  ys <- sort(unique(d$year))
  nat <- function(y, p) { v <- d$n_active[d$year == y & d$board_pathway == p]
                          if (length(v) == 1L) as.integer(v) else NA_integer_ }
  abog_field <- function(y, col) { v <- d[[col]][d$year == y & d$board_pathway == "ABOG"]
                                   if (length(v)) as.character(v[1]) else NA_character_ }
  if (!any(d$board_pathway == "ABOG"))
    stop("[mufflyaccess] artifact has no ABOG rows -- board_pathway must use ",
         "ABOG / ABU_NET_NEW / ABOG_PLUS_ABU (check casing).", call. = FALSE)
  data.frame(
    year            = ys,
    abog_active     = vapply(ys, nat, integer(1), p = "ABOG"),
    abu_net_new     = vapply(ys, nat, integer(1), p = "ABU_NET_NEW"),
    combined_active = vapply(ys, nat, integer(1), p = "ABOG_PLUS_ABU"),
    measure_year    = ys,
    snapshot_date   = as.Date(vapply(ys, abog_field, character(1), col = "snapshot_date")),
    method_version  = vapply(ys, abog_field, character(1), col = "method_version"),
    source_sha256   = vapply(ys, abog_field, character(1), col = "source_sha256"),
    stringsAsFactors = FALSE)
}

#' Select the URPS workforce artifact mufflyaccess serves
#'
#' @description Point the SSOT readers at a released isochrones artifact directory
#'   (one containing `urps_counts_by_year.csv` + `urps_manifest.json`). The
#'   directory is **validated** ([validate_urps_ssot()]) before it is adopted; an
#'   invalid artifact is rejected and the previous source restored. `dir = NULL`
#'   resets to the bundled bootstrap. The choice is stored in the
#'   `mufflyaccess.urps_artifact_dir` option (also honored via the
#'   `MUFFLYACCESS_URPS_ARTIFACT_DIR` environment variable).
#' @param dir Path to an isochrones `artifacts/workforce/` directory, or `NULL`
#'   to use the bundled artifact.
#' @return Invisibly the resolved directory (or `"bundled"`).
#' @seealso [urps_count()], [urps_provenance()], [validate_urps_ssot()]
#' @family URPS workforce
#' @examples
#' \dontrun{
#' use_urps_artifact("/path/to/isochrones/artifacts/workforce")
#' urps_provenance()$source_git_commit   # now the released commit
#' use_urps_artifact(NULL)               # back to bundled
#' }
#' @export
use_urps_artifact <- function(dir = NULL) {
  if (is.null(dir)) {
    options(mufflyaccess.urps_artifact_dir = NULL)
    return(invisible("bundled"))
  }
  dir <- normalizePath(dir, mustWork = TRUE)
  need <- c("urps_counts_by_year.csv", "urps_manifest.json")
  miss <- need[!file.exists(file.path(dir, need))]
  if (length(miss))
    stop("[use_urps_artifact] directory is missing ", paste(miss, collapse = ", "),
         ": ", dir, call. = FALSE)
  prev <- getOption("mufflyaccess.urps_artifact_dir")
  options(mufflyaccess.urps_artifact_dir = dir)
  tryCatch(validate_urps_ssot(),
           error = function(e) {
             options(mufflyaccess.urps_artifact_dir = prev)
             stop("[use_urps_artifact] artifact failed validation; keeping the ",
                  "previous source.\n", conditionMessage(e), call. = FALSE)
           })
  message("mufflyaccess: using URPS artifact ", dir)
  invisible(dir)
}

#' National URPS workforce count -- the published SSOT accessor
#'
#' @description The single-source-of-truth accessor for the national active URPS
#'   count. Consumers call this and **never hardcode or independently derive a
#'   national URPS count** (see `ARCHITECTURE.md`). Returns a bare integer.
#' @param year Integer measure year in 2013:2023 (default `2023L`). ABOG-only is
#'   available 2013-2023; the with-urology (ABU) cohort is a 2023 snapshot only.
#' @param include_urology Single non-`NA` logical. `FALSE` (default) = ABOG only;
#'   `TRUE` = both-pathway ABOG + ABU.
#' @return A length-1 integer `n_active`.
#' @seealso [urps_counts()], [urps_provenance()], [validate_urps_ssot()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' urps_count(2023L, include_urology = FALSE)  # 1031
#' urps_count(2023L, include_urology = TRUE)   # 1339
#' @export
urps_count <- function(year = 2023L, include_urology = FALSE) {
  if (length(year) != 1L)
    stop("[urps_count] `year` must be a single value.", call. = FALSE)
  if (!is.numeric(year))
    stop("[urps_count] `year` must be an integer/numeric value.", call. = FALSE)
  if (is.na(year))
    stop("[urps_count] `year` must not be NA.", call. = FALSE)
  if (length(include_urology) != 1L)
    stop("[urps_count] `include_urology` must be a single logical.", call. = FALSE)
  if (!is.logical(include_urology))
    stop("[urps_count] `include_urology` must be logical.", call. = FALSE)
  if (is.na(include_urology))
    stop("[urps_count] `include_urology` must not be NA.", call. = FALSE)

  year <- as.integer(year)
  w <- .urps_wide()
  if (!year %in% w$year)
    stop(sprintf("[urps_count] year %d not available (2013:2023).", year), call. = FALSE)
  col <- if (include_urology) "combined_active" else "abog_active"
  val <- w[[col]][w$year == year]
  if (is.na(val))
    stop(sprintf("[urps_count] with-urology count not available for %d (2023 only).", year),
         call. = FALSE)
  as.integer(val)
}

#' The complete canonical URPS workforce table
#'
#' @description The compact wide table `mufflyaccess` serves: one row per measure
#'   year (2013-2023) with `abog_active`, `abu_net_new`, `combined_active`, and
#'   provenance columns. `abu_net_new` / `combined_active` are `NA` before 2023.
#' @return A `data.frame` with columns `year`, `abog_active`, `abu_net_new`,
#'   `combined_active`, `measure_year`, `snapshot_date` (Date), `method_version`,
#'   `source_sha256`.
#' @seealso [urps_count()], [urps_provenance()], [validate_urps_ssot()]
#' @family URPS workforce
#' @examples
#' urps_counts()
#' @export
urps_counts <- function() .urps_wide()

#' Provenance / manifest for the URPS workforce SSOT
#'
#' @description Metadata for the active artifact: version, measure years,
#'   snapshot date, boards, geographic scope, definitions, source hash / git
#'   commit, method version, and the installed package version.
#' @return A named list; `measure_years` is integer, `snapshot_date` is a `Date`.
#' @seealso [urps_count()], [validate_urps_ssot()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' urps_provenance()$geographic_scope
#' @export
urps_provenance <- function() {
  m <- .urps_manifest()
  sf <- m$source_files
  src_sha <- if (is.data.frame(sf)) sf$sha256[1]
             else if (is.list(sf) && length(sf)) sf[[1]]$sha256
             else m$source_sha256
  list(
    artifact_version          = m$artifact_version,
    measure_years             = as.integer(m$measure_years),
    snapshot_date             = as.Date(m$snapshot_date),
    boards                    = m$boards,
    geographic_scope          = m$geographic_scope,
    active_in_year_definition = m$active_in_year_definition,
    deduplication_rule        = m$deduplication_rule,
    source_sha256             = src_sha %||% m$source_sha256,
    source_git_commit         = m$git_commit %||% m$source_git_commit,
    method_version            = m$method_version,
    package_version           = as.character(utils::packageVersion("mufflyaccess"))
  )
}

#' Validate the URPS workforce SSOT (fail loud)
#'
#' @description Checks a wide counts table against the frozen contract: required
#'   columns, unique measure years covering 2013-2023, well-formed 64-hex
#'   `source_sha256`, and the reconciliation identity
#'   `combined_active == abog_active + abu_net_new`. With no argument it validates
#'   the active artifact (bundled or the one selected by [use_urps_artifact()]),
#'   including its SHA-256 against the manifest when `digest` is available.
#' @param counts Optional wide counts `data.frame` (as from [urps_counts()]);
#'   `NULL` (default) validates the active artifact.
#' @return Invisibly `TRUE` on success; otherwise stops with the failed check.
#' @seealso [urps_count()], [urps_counts()], [urps_provenance()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' validate_urps_ssot()
#' @export
validate_urps_ssot <- function(counts = NULL) {
  bundled <- is.null(counts)
  w <- if (bundled) .urps_wide() else counts
  req <- c("year", "abog_active", "abu_net_new", "combined_active", "source_sha256")
  if (!all(req %in% names(w)))
    stop("[validate] counts table is missing required columns.", call. = FALSE)
  if (anyDuplicated(w$year))
    stop("[validate] measure years must be unique (duplicate year found).", call. = FALSE)
  miss <- setdiff(2013:2023, w$year)
  if (length(miss))
    stop(sprintf("[validate] missing measure year(s) %s; the series must cover 2013:2023.",
                 paste(miss, collapse = ", ")), call. = FALSE)
  sh <- w$source_sha256[!is.na(w$source_sha256)]
  if (!all(grepl("^[0-9a-f]{64}$", sh)))
    stop("[validate] malformed source_sha256 (each must be a 64-character hex hash).",
         call. = FALSE)
  ok <- is.na(w$combined_active) | is.na(w$abu_net_new) |
        (w$combined_active == w$abog_active + w$abu_net_new)
  if (!all(ok))
    stop("[validate] combined_active must reconcile as abog_active + abu_net_new.",
         call. = FALSE)
  if (bundled && requireNamespace("digest", quietly = TRUE)) {
    m <- .urps_manifest()
    expected <- m$artifact_sha256 %||% m$output_files$urps_counts_by_year_csv$sha256
    if (!is.null(expected)) {
      got <- digest::digest(file = .urps_path("urps_counts_by_year.csv"), algo = "sha256")
      if (!identical(got, expected))
        stop("[validate] canonical table SHA-256 does not match the manifest.", call. = FALSE)
    }
  }
  invisible(TRUE)
}
