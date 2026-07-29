# ==============================================================================
# The published URPS workforce SSOT interface (see ARCHITECTURE.md).
# isochrones builds + hashes the roster; mufflyaccess reads/validates/serves it;
# consumers call these functions and never derive a national URPS count.
#
# By default mufflyaccess serves a bundled BOOTSTRAP artifact
# (inst/extdata/urps_{counts_by_year.csv,manifest.json}). It is explicitly NOT a
# canonical release: urps_provenance()$canonical_release and $suitable_for_release
# are both FALSE. Point at a released isochrones artifact directory with
# use_urps_artifact("<dir>") (explicit call: FAILS CLOSED on an invalid artifact)
# or via the `mufflyaccess.urps_artifact_dir` option / MUFFLYACCESS_URPS_ARTIFACT_DIR
# env var (resolver path: an invalid source WARNS + falls back to the bundled
# bootstrap, and the fallback is revealed by urps_provenance()$artifact_source and
# $external_artifact_error -- unless options(mufflyaccess.urps_artifact_strict=TRUE),
# which turns the fallback into an error).
# ==============================================================================

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# bundled bootstrap directory (installed extdata, or inst/extdata under load_all)
.urps_bundled_dir <- function() {
  d <- system.file("extdata", package = "mufflyaccess")
  if (nzchar(d)) d else file.path("inst", "extdata")
}

# lightweight usability check for a candidate artifact directory; NULL == usable
.urps_dir_error <- function(dir) {
  if (is.null(dir) || !nzchar(dir)) return("empty path")
  if (!dir.exists(dir)) return(sprintf("directory does not exist (%s)", dir))
  need <- c("urps_counts_by_year.csv", "urps_manifest.json")
  miss <- need[!file.exists(file.path(dir, need))]
  if (length(miss)) return(sprintf("missing %s", paste(miss, collapse = ", ")))
  NULL
}

# Resolve the active artifact: an external directory selected via the option/env
# (validated for usability) else the bundled bootstrap. Returns
#   list(dir, source = "external" | "bundled_bootstrap", error)
# On an unusable external source: strict mode errors; otherwise warn + fall back
# and report the reason in `error` so urps_provenance() can surface it.
.urps_resolve <- function() {
  opt <- getOption("mufflyaccess.urps_artifact_dir", NULL)
  env <- Sys.getenv("MUFFLYACCESS_URPS_ARTIFACT_DIR", "")
  requested <- if (!is.null(opt) && nzchar(opt)) opt
               else if (nzchar(env)) env else NULL
  bundled <- .urps_bundled_dir()
  if (is.null(requested))
    return(list(dir = bundled, source = "bundled_bootstrap", error = NULL))
  err <- .urps_dir_error(requested)
  if (is.null(err))
    return(list(dir = requested, source = "external", error = NULL))
  if (isTRUE(getOption("mufflyaccess.urps_artifact_strict", FALSE)))
    stop(sprintf("[mufflyaccess] requested URPS artifact is unusable and strict mode is on (%s): %s",
                 err, requested), call. = FALSE)
  warning(sprintf("[mufflyaccess] requested URPS artifact is unusable (%s); serving the bundled bootstrap instead: %s",
                  err, requested), call. = FALSE)
  list(dir = bundled, source = "bundled_bootstrap", error = err)
}

.urps_artifact_dir <- function() .urps_resolve()$dir

.urps_path <- function(file, dir = .urps_artifact_dir()) {
  p <- file.path(dir, file)
  if (!file.exists(p)) {                                   # dev (load_all) fallback
    alt <- file.path("inst", "extdata", file)
    if (file.exists(alt)) return(alt)
  }
  p
}

.urps_read_long <- function(dir = .urps_artifact_dir()) {
  utils::read.csv(
    .urps_path("urps_counts_by_year.csv", dir),
    stringsAsFactors = FALSE, na.strings = c("", "NA"),
    colClasses = c(year = "integer", board_pathway = "character",
                   n_active = "integer", n_ever_certified = "integer",
                   n_retired = "integer", snapshot_date = "character",
                   source_sha256 = "character", method_version = "character"))
}

.urps_manifest <- function(dir = .urps_artifact_dir()) {
  jsonlite::fromJSON(.urps_path("urps_manifest.json", dir), simplifyVector = TRUE)
}

# normalized geography code for the served artifact (from the manifest scope)
.urps_scope_code <- function(dir = .urps_artifact_dir()) {
  s <- tolower(.urps_manifest(dir)$geographic_scope %||% "")
  if (grepl("contiguous", s) || grepl("conus", s)) "CONUS"
  else if (grepl("national|united states|nationwide", s)) "NATIONAL"
  else toupper(.urps_manifest(dir)$geographic_scope %||% NA_character_)
}

.urps_wide <- function(dir = .urps_artifact_dir()) {
  d <- .urps_read_long(dir)
  ys <- sort(unique(d$year))
  nat <- function(y, p) { v <- d$n_active[d$year == y & d$board_pathway == p]
                          if (length(v) == 1L) as.integer(v) else NA_integer_ }
  abog_field <- function(y, col) { v <- d[[col]][d$year == y & d$board_pathway == "ABOG"]
                                   if (length(v)) as.character(v[1]) else NA_character_ }
  if (!any(d$board_pathway == "ABOG"))
    stop("[mufflyaccess] artifact has no ABOG rows -- board_pathway must use ",
         "ABOG / ABU_NET_NEW / ABOG_PLUS_ABU (check casing).", call. = FALSE)
  abu <- vapply(ys, nat, integer(1), p = "ABU_NET_NEW")
  comb <- vapply(ys, nat, integer(1), p = "ABOG_PLUS_ABU")
  data.frame(
    year                   = ys,
    abog_active            = vapply(ys, nat, integer(1), p = "ABOG"),
    abu_net_new            = abu,
    combined_active        = comb,
    measure_year           = ys,
    snapshot_date          = as.Date(vapply(ys, abog_field, character(1), col = "snapshot_date")),
    method_version         = vapply(ys, abog_field, character(1), col = "method_version"),
    source_sha256          = vapply(ys, abog_field, character(1), col = "source_sha256"),
    # explicit missingness so consumers never mistake NA for zero
    abog_active_status     = "snapshot-derived",
    abu_net_new_status     = ifelse(is.na(abu),  "unavailable", "snapshot"),
    combined_active_status = ifelse(is.na(comb), "unavailable", "derived"),
    stringsAsFactors = FALSE)
}

#' Select the URPS workforce artifact mufflyaccess serves
#'
#' @description Point the SSOT readers at a released isochrones artifact directory
#'   (one containing `urps_counts_by_year.csv` + `urps_manifest.json`). This
#'   explicit call **fails closed**: the directory is fully validated
#'   ([validate_urps_ssot()]) before it is adopted, and an invalid artifact is
#'   **rejected with an error while the previously active source is left
#'   unchanged** -- it never silently continues as if the switch succeeded.
#'   `dir = NULL` resets to the bundled bootstrap. The choice is stored in the
#'   `mufflyaccess.urps_artifact_dir` option (also honored via the
#'   `MUFFLYACCESS_URPS_ARTIFACT_DIR` environment variable). When the source is set
#'   through the option/env instead of this function, an unusable directory does
#'   **not** error at read time: it warns and falls back to the bundled bootstrap,
#'   and the fallback is revealed by `urps_provenance()$artifact_source` /
#'   `$external_artifact_error` (set `options(mufflyaccess.urps_artifact_strict =
#'   TRUE)` to make that fallback an error).
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
  err <- .urps_dir_error(dir)
  if (!is.null(err))
    stop("[use_urps_artifact] ", err, ": ", dir,
         "\nThe previous source is unchanged.", call. = FALSE)
  prev <- getOption("mufflyaccess.urps_artifact_dir")
  options(mufflyaccess.urps_artifact_dir = dir)
  tryCatch(validate_urps_ssot(),
           error = function(e) {
             options(mufflyaccess.urps_artifact_dir = prev)   # fail closed
             stop("[use_urps_artifact] artifact failed validation; the previous ",
                  "source is unchanged.\n", conditionMessage(e), call. = FALSE)
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
#' @param incomplete How to handle a year/cohort combination the artifact does not
#'   carry (e.g. with-urology before 2023): `"error"` (default) stops with an
#'   explanatory message; `"na"` returns `NA_integer_`. Never returns a silent 0.
#' @param geography Optional single string asserting the geography the caller
#'   expects (e.g. `"CONUS"` or `"national"`). `NULL` (default) accepts whatever
#'   the served artifact declares. A mismatch is an **error** -- mufflyaccess does
#'   not re-project counts onto a geography the artifact was not built for.
#' @return A length-1 integer `n_active` (or `NA_integer_` when `incomplete = "na"`
#'   and the value is unavailable).
#' @seealso [urps_counts()], [urps_provenance()], [validate_urps_ssot()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' urps_count(2023L, include_urology = FALSE)  # 1031
#' urps_count(2023L, include_urology = TRUE)   # 1339
#' urps_count(2013L, include_urology = TRUE, incomplete = "na")  # NA (ABU is 2023 only)
#' @export
urps_count <- function(year = 2023L, include_urology = FALSE,
                       incomplete = c("error", "na"), geography = NULL) {
  incomplete <- match.arg(incomplete)
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

  if (!is.null(geography)) {
    if (!is.character(geography) || length(geography) != 1L || is.na(geography))
      stop("[urps_count] `geography` must be a single string or NULL.", call. = FALSE)
    served <- .urps_scope_code()
    if (!identical(toupper(geography), served))
      stop(sprintf("[urps_count] geography '%s' not available; the served artifact covers '%s' (%s). mufflyaccess does not re-project counts onto another geography.",
                   geography, served %||% "unknown", .urps_manifest()$geographic_scope %||% "scope unset"),
           call. = FALSE)
  }

  year <- as.integer(year)
  w <- .urps_wide()
  if (!year %in% w$year)
    stop(sprintf("[urps_count] year %d not available (2013:2023).", year), call. = FALSE)
  col <- if (include_urology) "combined_active" else "abog_active"
  val <- w[[col]][w$year == year]
  if (is.na(val)) {
    if (incomplete == "na") return(NA_integer_)
    stop(sprintf("[urps_count] %s count not available for %d (the with-urology/ABU cohort is a 2023 snapshot only). Pass incomplete = \"na\" to receive NA instead.",
                 if (include_urology) "with-urology" else "count", year),
         call. = FALSE)
  }
  as.integer(val)
}

#' The complete canonical URPS workforce table
#'
#' @description The compact wide table `mufflyaccess` serves: one row per measure
#'   year (2013-2023) with `abog_active`, `abu_net_new`, `combined_active`,
#'   explicit `*_status` columns, and provenance columns. `abu_net_new` /
#'   `combined_active` are `NA` before 2023 (status `"unavailable"`).
#' @return A `data.frame` with columns `year`, `abog_active`, `abu_net_new`,
#'   `combined_active`, `measure_year`, `snapshot_date` (Date), `method_version`,
#'   `source_sha256`, `abog_active_status`, `abu_net_new_status`,
#'   `combined_active_status`.
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
#'   commit, method version, the installed package version, and release-readiness
#'   flags. `artifact_source` is `"external"` when a released artifact is served
#'   and `"bundled_bootstrap"` otherwise (including after a silent option/env
#'   fallback, whose reason is in `external_artifact_error`). `canonical_release`
#'   and `suitable_for_release` are `FALSE` for the bootstrap.
#' @return A named list; `measure_years` is integer, `snapshot_date` is a `Date`.
#' @seealso [urps_count()], [validate_urps_ssot()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' urps_provenance()$geographic_scope
#' urps_provenance()$canonical_release   # FALSE for the bundled bootstrap
#' @export
urps_provenance <- function() {
  r <- .urps_resolve()
  m <- .urps_manifest(r$dir)
  sf <- m$source_files
  src_sha <- if (is.data.frame(sf)) sf$sha256[1]
             else if (is.list(sf) && length(sf)) sf[[1]]$sha256
             else m$source_sha256
  list(
    artifact_version          = m$artifact_version,
    artifact_source           = r$source,
    canonical_release         = isTRUE(m$canonical_release),
    suitable_for_release      = isTRUE(m$suitable_for_release),
    contract_version          = m$contract_version %||% NA_character_,
    external_artifact_error   = r$error %||% NA_character_,
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
#' @param require_external If `TRUE`, additionally require that the active artifact
#'   is an external released directory (not the bundled bootstrap); errors
#'   otherwise. Use in release/integration gates.
#' @return Invisibly `TRUE` on success; otherwise stops with the failed check.
#' @seealso [urps_count()], [urps_counts()], [urps_provenance()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' validate_urps_ssot()
#' @export
validate_urps_ssot <- function(counts = NULL, require_external = FALSE) {
  if (isTRUE(require_external)) {
    r <- .urps_resolve()
    if (!identical(r$source, "external"))
      stop("[validate] require_external = TRUE but the active artifact is the bundled ",
           "bootstrap; call use_urps_artifact('<released dir>') first.", call. = FALSE)
  }
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
