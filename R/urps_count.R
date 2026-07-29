# ==============================================================================
# The published URPS workforce SSOT interface (see ARCHITECTURE.md).
# isochrones builds + hashes the roster; mufflyaccess reads/validates/serves it;
# consumers call these functions and never derive a national URPS count.
#
# Ships a compact canonical table (inst/extdata/urps_counts_by_year.csv, LONG,
# board_pathway in {ABOG, ABU_NET_NEW, ABOG_PLUS_ABU}) + manifest. This is a
# BOOTSTRAP of what isochrones will publish under artifacts/workforce/.
# ==============================================================================

.urps_extdata <- function(file) {
  p <- system.file("extdata", file, package = "mufflyaccess")
  if (!nzchar(p)) p <- file.path("inst", "extdata", file)   # dev (load_all) fallback
  p
}

.urps_read_long <- function() {
  utils::read.csv(
    .urps_extdata("urps_counts_by_year.csv"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"),
    colClasses = c(year = "integer", board_pathway = "character",
                   n_active = "integer", n_ever_certified = "integer",
                   n_retired = "integer", snapshot_date = "character",
                   source_sha256 = "character", method_version = "character"))
}

.urps_manifest <- function() {
  jsonlite::fromJSON(.urps_extdata("urps_manifest.json"), simplifyVector = TRUE)
}

# pivot the LONG artifact to the compact WIDE published table
.urps_wide <- function() {
  d <- .urps_read_long()
  ys <- sort(unique(d$year))
  nat <- function(y, p) { v <- d$n_active[d$year == y & d$board_pathway == p]
                          if (length(v) == 1L) as.integer(v) else NA_integer_ }
  abog_field <- function(y, col) { v <- d[[col]][d$year == y & d$board_pathway == "ABOG"]
                                   if (length(v)) v[1] else NA }
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

#' National URPS workforce count -- the published SSOT accessor
#'
#' @description The single-source-of-truth accessor for the national active URPS
#'   count. Consumers (`cliff` / `twostep` / manuscripts / apps) call this and
#'   **never hardcode or independently derive a national URPS count** (see
#'   `ARCHITECTURE.md`). Returns a bare integer; provenance lives in
#'   [urps_counts()] / [urps_provenance()].
#' @param year Integer measure year in 2013:2023 (default `2023L`). ABOG-only is
#'   available 2013-2023; the with-urology (ABU) cohort is a 2023 snapshot only.
#' @param include_urology Single non-`NA` logical. `FALSE` (default) = ABOG /
#'   OB-GYN pathway only; `TRUE` = both-pathway ABOG + ABU.
#' @return A length-1 integer `n_active`.
#' @seealso [urps_counts()], [urps_provenance()], [validate_urps_ssot()]
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
#' @description The compact wide table `mufflyaccess` publishes: one row per
#'   measure year (2013-2023) with `abog_active`, `abu_net_new`,
#'   `combined_active`, and provenance columns. `abu_net_new` / `combined_active`
#'   are `NA` before 2023 (ABU is a 2023 snapshot).
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
#' @description Metadata for the canonical table: version, measure years,
#'   snapshot date, boards, geographic scope, the active-in-year definition, the
#'   deduplication rule, source hashes / git commit, method version, and the
#'   installed package version. Every returned count traces back to this.
#' @return A named list; `measure_years` is integer, `snapshot_date` is a `Date`.
#' @seealso [urps_count()], [validate_urps_ssot()]
#' @family URPS workforce
#' @examples
#' urps_provenance()$geographic_scope
#' @export
urps_provenance <- function() {
  m <- .urps_manifest()
  list(
    artifact_version          = m$artifact_version,
    measure_years             = as.integer(m$measure_years),
    snapshot_date             = as.Date(m$snapshot_date),
    boards                    = m$boards,
    geographic_scope          = m$geographic_scope,
    active_in_year_definition = m$active_in_year_definition,
    deduplication_rule        = m$deduplication_rule,
    source_sha256             = m$source_sha256,
    source_git_commit         = m$source_git_commit,
    method_version            = m$method_version,
    package_version           = as.character(utils::packageVersion("mufflyaccess"))
  )
}

#' Validate the URPS workforce SSOT (fail loud)
#'
#' @description Checks a wide counts table against the frozen contract: required
#'   columns, unique measure years covering 2013-2023, well-formed 64-hex
#'   `source_sha256`, and the reconciliation identity
#'   `combined_active == abog_active + abu_net_new` (1339 for 2023). Called with
#'   no argument it validates the bundled table (and its SHA-256 against the
#'   manifest when `digest` is available).
#' @param counts Optional wide counts `data.frame` (as from [urps_counts()]);
#'   `NULL` (default) validates the bundled table.
#' @return Invisibly `TRUE` on success; otherwise stops with the failed check.
#' @seealso [urps_count()], [urps_counts()], [urps_provenance()]
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
    stop("[validate] combined_active must reconcile as abog_active + abu_net_new ",
         "(1339 for 2023).", call. = FALSE)
  if (bundled && requireNamespace("digest", quietly = TRUE)) {
    m <- .urps_manifest()
    got <- digest::digest(file = .urps_extdata("urps_counts_by_year.csv"), algo = "sha256")
    if (!identical(got, m$artifact_sha256))
      stop("[validate] canonical table SHA-256 does not match the manifest.", call. = FALSE)
  }
  invisible(TRUE)
}
