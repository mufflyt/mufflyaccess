# ==============================================================================
# The published URPS workforce SSOT interface (see ARCHITECTURE.md).
# isochrones builds + hashes the roster; mufflyaccess reads/validates/serves it;
# consumers call these functions and never derive a national URPS count.
#
# Contract v3.0.0 schema (isochrones artifacts/workforce/):
#   urps_counts_by_year.csv columns:
#     year, measure, geography, board_pathway, n_active, n_ever_certified,
#     n_retired, snapshot_date, source_sha256, method_version
#   measure   in {board_certified_active (2013-2023), roster_snapshot (2025)}
#   geography in {national, conus}
#   board_pathway in {ABOG, ABU_NET_NEW, ABOG_PLUS_ABU}
#
# Canonical 2023 estimand: board_certified_active / national / ABOG_PLUS_ABU = 1306
# (CONUS = 1303), keyed on the URPS SUBSPECIALTY cert year (training-accurate).
# 1339 is the 2025 roster_snapshot, NOT the 2023 active count.
# RETIRED: v2.1.0's 1332 / 1329 used the primary-cert basis and must never be
# presented as current (see urps_lineage() / urps_retired_values()).
#
# mufflyaccess ships the v3.0.0 counts as a bundled BOOTSTRAP: it serves the
# correct numbers by default but is NOT the canonical immutable release
# (urps_provenance()$canonical_release is FALSE unless you point at the external
# released directory). use_urps_artifact("<dir>") adopts an external isochrones
# release and FAILS CLOSED on an invalid one; the option/env resolver path warns
# + falls back and reveals it via urps_provenance().
# ==============================================================================

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

.urps_measures        <- c("board_certified_active", "roster_snapshot")
.urps_geographies     <- c("national", "conus")
.urps_pathways        <- c("ABOG", "ABU_NET_NEW", "ABOG_PLUS_ABU")
.urps_bca_years       <- 2013:2023
.urps_snapshot_year   <- 2025L
.urps_contract_majors <- 3L                       # supported major contract version (current; v2.x retired)

# ---- artifact resolution ----------------------------------------------------

.urps_bundled_dir <- function() {
  d <- system.file("extdata", package = "mufflyaccess")
  if (nzchar(d)) d else file.path("inst", "extdata")
}

.urps_dir_error <- function(dir) {
  if (is.null(dir) || !nzchar(dir)) return("empty path")
  if (!dir.exists(dir)) return(sprintf("directory does not exist (%s)", dir))
  need <- c("urps_counts_by_year.csv", "urps_manifest.json")
  miss <- need[!file.exists(file.path(dir, need))]
  if (length(miss)) return(sprintf("missing %s", paste(miss, collapse = ", ")))
  NULL
}

# option/env external directory (existence-validated) else bundled bootstrap.
# returns list(dir, source = "external"|"bundled_bootstrap", error)
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
  if (!file.exists(p)) {
    alt <- file.path("inst", "extdata", file)                 # dev (load_all) fallback
    if (file.exists(alt)) return(alt)
  }
  p
}

.urps_read_long <- function(dir = .urps_artifact_dir()) {
  d <- utils::read.csv(.urps_path("urps_counts_by_year.csv", dir),
                       stringsAsFactors = FALSE, na.strings = c("", "NA"))
  for (col in intersect(c("year", "n_active", "n_ever_certified", "n_retired"), names(d)))
    d[[col]] <- as.integer(d[[col]])                # coerce present numeric columns only
  d
}

.urps_manifest <- function(dir = .urps_artifact_dir()) {
  jsonlite::fromJSON(.urps_path("urps_manifest.json", dir), simplifyVector = TRUE)
}

.urps_contract <- function(dir = .urps_artifact_dir()) {
  p <- .urps_path("urps_release_contract.json", dir)
  if (file.exists(p)) jsonlite::fromJSON(p, simplifyVector = TRUE) else NULL
}

# ---- small validators -------------------------------------------------------

.urps_norm_choice <- function(x, arg, known) {
  if (!is.character(x) || length(x) != 1L || is.na(x))
    stop(sprintf("[urps_count] `%s` must be a single string.", arg), call. = FALSE)
  x <- tolower(trimws(x))                                     # case/space normalized
  if (!x %in% known)
    stop(sprintf("[urps_count] unknown %s '%s'; use one of %s.",
                 arg, x, paste(known, collapse = ", ")), call. = FALSE)
  x
}

.urps_semver <- function(v) {
  if (is.null(v) || length(v) != 1L || is.na(v) ||
      !grepl("^[0-9]+\\.[0-9]+\\.[0-9]+([-+].*)?$", v)) return(NULL)
  as.integer(strsplit(sub("[-+].*$", "", v), ".", fixed = TRUE)[[1]])
}

.urps_effective_contract_version <- function(m, contract) {
  m$contract_version %||% (if (!is.null(contract)) contract$contract_version) %||%
    m$artifact_version %||% NA_character_
}

.urps_parquet_reader <- function() {
  if (requireNamespace("arrow", quietly = TRUE))
    return(function(p) as.data.frame(arrow::read_parquet(p)))
  if (requireNamespace("nanoparquet", quietly = TRUE))
    return(function(p) as.data.frame(nanoparquet::read_parquet(p)))
  NULL
}

# ---- release-readiness flags ------------------------------------------------

.urps_release_flags <- function(dir, source) {
  m <- .urps_manifest(dir)
  is_external    <- identical(source, "external")
  looks_boot     <- grepl("bootstrap", m$method_version %||% "", ignore.case = TRUE)
  canonical <- if (!is.null(m$canonical_release)) isTRUE(m$canonical_release)
               else is_external && !looks_boot
  suitable  <- if (!is.null(m$suitable_for_release)) isTRUE(m$suitable_for_release)
               else canonical
  list(canonical_release = canonical, suitable_for_release = suitable)
}

# ---- exported API -----------------------------------------------------------

#' Select the URPS workforce artifact mufflyaccess serves
#'
#' @description Point the SSOT readers at a released isochrones artifact directory
#'   (`artifacts/workforce/`). This explicit call **fails closed**: the directory
#'   is fully validated ([validate_urps_artifact()]) *before* it is adopted, and
#'   an invalid artifact is rejected with an error while the previously active
#'   source is left completely unchanged. `dir = NULL` resets to the bundled
#'   bootstrap. Setting the source through the `mufflyaccess.urps_artifact_dir`
#'   option / `MUFFLYACCESS_URPS_ARTIFACT_DIR` environment variable instead does
#'   not error at read time: an unusable directory warns and falls back to the
#'   bundled bootstrap, revealed by `urps_provenance()$artifact_source` /
#'   `$external_artifact_error` (`options(mufflyaccess.urps_artifact_strict = TRUE)`
#'   makes that fallback an error).
#' @param dir Path to an isochrones `artifacts/workforce/` directory, or `NULL`.
#' @return Invisibly the resolved directory (or `"bundled"`).
#' @seealso [urps_count()], [urps_provenance()], [validate_urps_artifact()]
#' @family URPS workforce
#' @examples
#' \dontrun{
#' use_urps_artifact("path/to/isochrones/artifacts/workforce")  # validated; fails closed
#' urps_provenance()$artifact_source                            # "external"
#' use_urps_artifact(NULL)                                      # back to the bundled bootstrap
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
  tryCatch(validate_urps_artifact(dir),                       # validate BEFORE adopting
           error = function(e)
             stop("[use_urps_artifact] artifact failed validation; the previous ",
                  "source is unchanged.\n", conditionMessage(e), call. = FALSE))
  options(mufflyaccess.urps_artifact_dir = dir)
  message("mufflyaccess: using URPS artifact ", dir)
  invisible(dir)
}

#' National URPS workforce count -- the published SSOT accessor
#'
#' @description The single-source-of-truth accessor for the national urogynecology
#'   / reconstructive-pelvic-surgery (URPS) workforce count. Consumers call this
#'   and **never hardcode or independently derive a national URPS count** (see
#'   `ARCHITECTURE.md`). A count is only interpretable once its *measure*, *year*,
#'   *geography*, and *pathway inclusion* are fixed, so all four are explicit
#'   arguments.
#'
#' @details
#' Under contract v3.0.0 `board_certified_active` is keyed on the URPS
#' **subspecialty** certification year (training-accurate, post-fellowship), so a
#' provider whose subspecialty certification postdates the requested year is not
#' yet counted. The two measures answer different questions and are **not**
#' interchangeable:
#' \itemize{
#'   \item `board_certified_active` -- the estimated active board-certified
#'     workforce in a given year (2013-2023).
#'   \item `roster_snapshot` -- the 2025 headcount of the identified roster
#'     (includes providers whose subspecialty certification postdates 2023).
#' }
#' Validation errors are raised (never silent) for an out-of-window year, an
#' unknown measure/geography, a non-scalar or `NA` argument, and -- unless
#' `incomplete = "na"` -- an absent published cell.
#'
#' @section Estimands (contract v3.0.0):
#' The published 2023 `board_certified_active` and 2025 `roster_snapshot` cells:
#' \itemize{
#'   \item national / 2023 active: ABOG 1027 + ABU net-new 279 = **1306**
#'   \item conus / 2023 active: ABOG 1026 + ABU net-new 277 = **1303**
#'   \item national / 2025 roster: 1031 + 308 = **1339**; conus = 1336
#' }
#' **1339 is the 2025 roster snapshot, not the 2023 active count. 1332 / 1329 are
#' RETIRED v2.1.0 cells** (primary-cert basis) surfaced only by [urps_lineage()] /
#' [urps_retired_values()] and must never be presented as current.
#'
#' @param year Integer measure year. `board_certified_active` covers 2013-2023;
#'   `roster_snapshot` is the 2025 snapshot. A year outside a measure's window is
#'   a hard error.
#' @param measure `"board_certified_active"` (default; the active-in-year cohort)
#'   or `"roster_snapshot"` (the 2025 roster). Case-insensitive.
#' @param geography `"national"` (default) or `"conus"`. Case-insensitive.
#' @param include_urology Single non-`NA` logical. `FALSE` (default) = ABOG only
#'   (`ABOG` pathway); `TRUE` = both-pathway ABOG + ABU (`ABOG_PLUS_ABU`).
#' @param incomplete How to handle a published cell that is absent/`NA`:
#'   `"error"` (default) stops with an explanatory message; `"na"` returns
#'   `NA_integer_`. A year outside a measure's declared window is always a hard
#'   error, never a silent `NA`.
#' @param details If `TRUE`, return a labelled list instead of a bare integer so a
#'   downstream caller never receives a context-free number (see **Value**).
#'
#' @return With `details = FALSE` (default), a length-1 integer `n_active` (or
#'   `NA_integer_` when `incomplete = "na"` and the cell is absent). With
#'   `details = TRUE`, a named list:
#'   \describe{
#'     \item{count}{the integer count}
#'     \item{year, measure, geography, include_urology}{the resolved request}
#'     \item{board_pathway}{`"ABOG"` or `"ABOG_PLUS_ABU"`}
#'     \item{value_status}{`"observed"` (ABOG) or `"derived"` (ABOG_PLUS_ABU)}
#'     \item{snapshot_date}{source roster snapshot `Date`}
#'     \item{contract_version, artifact_version, source_git_commit}{provenance}
#'     \item{canonical_release}{`TRUE` only when serving an external release}
#'     \item{artifact_source}{`"external"` or `"bundled_bootstrap"`}
#'   }
#' @seealso [urps_counts()], [urps_provenance()], [urps_lineage()],
#'   [validate_urps_ssot()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' urps_count(2023, "board_certified_active", "national", FALSE)  # 1027 (ABOG only)
#' urps_count(2023, "board_certified_active", "national", TRUE)   # 1306 (with urology)
#' urps_count(2023, "board_certified_active", "conus",    TRUE)   # 1303
#' urps_count(2025, "roster_snapshot",        "national", TRUE)   # 1339 (2025 roster)
#'
#' # a labelled record for a footnote / caption (never a context-free 1306):
#' str(urps_count(2023, "board_certified_active", "national", TRUE, details = TRUE))
#'
#' # out-of-window requests are hard errors (a measure is only valid in its window):
#' try(urps_count(2025, "board_certified_active"))  # error: bca is 2013-2023
#' try(urps_count(2023, "roster_snapshot"))         # error: roster is 2025 only
#' @export
urps_count <- function(year = 2023L, measure = "board_certified_active",
                       geography = "national", include_urology = FALSE,
                       incomplete = c("error", "na"), details = FALSE) {
  incomplete <- match.arg(incomplete)
  if (length(year) != 1L)   stop("[urps_count] `year` must be a single value.", call. = FALSE)
  if (!is.numeric(year))    stop("[urps_count] `year` must be an integer/numeric value.", call. = FALSE)
  if (is.na(year))          stop("[urps_count] `year` must not be NA.", call. = FALSE)
  measure   <- .urps_norm_choice(measure,   "measure",   .urps_measures)
  geography <- .urps_norm_choice(geography, "geography", .urps_geographies)
  if (length(include_urology) != 1L) stop("[urps_count] `include_urology` must be a single logical.", call. = FALSE)
  if (!is.logical(include_urology))  stop("[urps_count] `include_urology` must be logical.", call. = FALSE)
  if (is.na(include_urology))        stop("[urps_count] `include_urology` must not be NA.", call. = FALSE)

  year <- as.integer(year)
  if (measure == "board_certified_active" && !(year %in% .urps_bca_years))
    stop(sprintf("[urps_count] board_certified_active is defined for %d-%d; year %d is an unsupported year.",
                 min(.urps_bca_years), max(.urps_bca_years), year), call. = FALSE)
  if (measure == "roster_snapshot" && year != .urps_snapshot_year)
    stop(sprintf("[urps_count] roster_snapshot is the %d roster snapshot; year %d is not available for that measure.",
                 .urps_snapshot_year, year), call. = FALSE)

  d <- .urps_read_long()
  pathway <- if (include_urology) "ABOG_PLUS_ABU" else "ABOG"
  sel <- d$year == year & d$measure == measure &
         d$geography == geography & d$board_pathway == pathway
  val <- d$n_active[sel]
  if (length(val) == 0L || is.na(val[1])) {
    if (incomplete == "na") return(NA_integer_)
    stop(sprintf("[urps_count] no published %s / %s / %s count for year %d. Pass incomplete = \"na\" for NA.",
                 measure, geography, pathway, year), call. = FALSE)
  }
  val <- as.integer(val[1])
  if (!isTRUE(details)) return(val)

  r <- .urps_resolve(); m <- .urps_manifest(r$dir); ct <- .urps_contract(r$dir)
  fl <- .urps_release_flags(r$dir, r$source)
  list(count = val, year = year, measure = measure, geography = geography,
       include_urology = include_urology, board_pathway = pathway,
       value_status = if (pathway == "ABOG_PLUS_ABU") "derived" else "observed",
       snapshot_date = as.Date(d$snapshot_date[sel][1]),
       contract_version = .urps_effective_contract_version(m, ct),
       artifact_version = m$artifact_version,
       source_git_commit = m$git_commit %||% m$source_git_commit,
       canonical_release = fl$canonical_release,
       artifact_source = r$source)
}

#' A wide URPS workforce slice for one measure x geography
#'
#' @description One row per year for the chosen `measure`/`geography`, pivoted
#'   wide across pathways, with explicit missingness columns. Defaults to the
#'   canonical `board_certified_active` / `national` slice (years 2013-2023). Use
#'   [urps_counts_long()] for the complete long table across all cells, or
#'   [urps_count()] for a single value.
#' @param measure `"board_certified_active"` (default) or `"roster_snapshot"`.
#'   Case-insensitive.
#' @param geography `"national"` (default) or `"conus"`. Case-insensitive.
#' @return A `data.frame` with one row per measure year and columns:
#'   \describe{
#'     \item{year, measure, geography}{the slice keys}
#'     \item{abog_active, abu_net_new, combined_active}{counts per pathway
#'       (`combined_active == abog_active + abu_net_new`)}
#'     \item{measure_year}{alias of `year`, to keep the measure year distinct from
#'       the snapshot date}
#'     \item{snapshot_date}{source roster `Date`}
#'     \item{method_version, source_sha256}{provenance}
#'     \item{abog_active_status, abu_net_new_status, combined_active_status}{
#'       `"observed"` / `"derived"` / `"unavailable"` -- so `NA` is never mistaken
#'       for a genuine zero}
#'   }
#' @seealso [urps_count()], [urps_counts_long()], [urps_provenance()]
#' @family URPS workforce
#' @examples
#' urps_counts()                                   # board_certified_active / national
#' utils::tail(urps_counts("board_certified_active", "conus"), 3)
#' @export
urps_counts <- function(measure = "board_certified_active", geography = "national") {
  measure   <- .urps_norm_choice(measure,   "measure",   .urps_measures)
  geography <- .urps_norm_choice(geography, "geography", .urps_geographies)
  d <- .urps_read_long()
  d <- d[d$measure == measure & d$geography == geography, , drop = FALSE]
  if (!any(d$board_pathway == "ABOG"))
    stop("[mufflyaccess] artifact has no ABOG rows for ", measure, " / ", geography,
         " -- check the artifact schema (measure/geography/board_pathway casing).", call. = FALSE)
  ys  <- sort(unique(d$year))
  nat <- function(y, p) { v <- d$n_active[d$year == y & d$board_pathway == p]
                          if (length(v) == 1L) as.integer(v) else NA_integer_ }
  fld <- function(y, col) { v <- d[[col]][d$year == y & d$board_pathway == "ABOG"]
                            if (length(v)) as.character(v[1]) else NA_character_ }
  abu  <- vapply(ys, nat, integer(1), p = "ABU_NET_NEW")
  comb <- vapply(ys, nat, integer(1), p = "ABOG_PLUS_ABU")
  data.frame(
    year                   = ys,
    measure                = measure,
    geography              = geography,
    abog_active            = vapply(ys, nat, integer(1), p = "ABOG"),
    abu_net_new            = abu,
    combined_active        = comb,
    measure_year           = ys,
    snapshot_date          = as.Date(vapply(ys, fld, character(1), col = "snapshot_date")),
    method_version         = vapply(ys, fld, character(1), col = "method_version"),
    source_sha256          = vapply(ys, fld, character(1), col = "source_sha256"),
    abog_active_status     = "observed",
    abu_net_new_status     = ifelse(is.na(abu),  "unavailable", "observed"),
    combined_active_status = ifelse(is.na(comb), "unavailable", "derived"),
    stringsAsFactors = FALSE)
}

#' The complete long URPS workforce table (all measures x geographies)
#'
#' @description The full served artifact as a tidy long table -- every
#'   `year x measure x geography x board_pathway` cell -- for callers that want to
#'   filter or pivot themselves. [urps_counts()] returns a convenient wide slice
#'   and [urps_count()] a single value.
#' @return A `data.frame` with columns `year`, `measure`, `geography`,
#'   `board_pathway`, `n_active`, `n_ever_certified`, `n_retired`,
#'   `snapshot_date`, `source_sha256`, `method_version`.
#' @seealso [urps_counts()], [urps_count()], [urps_provenance()]
#' @family URPS workforce
#' @examples
#' d <- urps_counts_long()
#' d[d$year == 2023 & d$geography == "national", c("measure", "board_pathway", "n_active")]
#' @export
urps_counts_long <- function() .urps_read_long()

#' Provenance / manifest for the URPS workforce SSOT
#'
#' @description Everything needed to cite or audit the served numbers: contract /
#'   artifact versions, the measures and geographies, the snapshot date, the
#'   active-in-year and deduplication definitions, the source hash and git commit,
#'   the disclosure-ready source wording, release-readiness flags, and the recorded
#'   retired cells.
#' @details `artifact_source` is `"external"` when a released artifact is served
#'   and `"bundled_bootstrap"` otherwise -- including after a silent option/env
#'   fallback, whose reason is then in `external_artifact_error`.
#'   `canonical_release` / `suitable_for_release` are `FALSE` for the bootstrap.
#'   Accessing this on an unusable external source emits a warning (see
#'   [use_urps_artifact()]).
#' @return A named list:
#'   \describe{
#'     \item{artifact_version, contract_version}{version strings (e.g. `"3.0.0"`)}
#'     \item{artifact_source}{`"external"` or `"bundled_bootstrap"`}
#'     \item{canonical_release, suitable_for_release}{release-readiness flags}
#'     \item{canonical_2023_estimand}{human-readable canonical-cell statement}
#'     \item{external_artifact_error}{`NULL`, or the fallback reason}
#'     \item{measure_years}{integer vector (2013:2023)}
#'     \item{measures, geographies, boards}{the published dimensions}
#'     \item{snapshot_date}{a `Date`; distinct from the measure year}
#'     \item{roster_reflects_certifications_through}{last cert year in the roster}
#'     \item{geographic_scope, active_in_year_definition, deduplication_rule}{
#'       definitional metadata}
#'     \item{source_sha256, source_git_commit, git_commit_semantics}{source
#'       integrity + commit provenance}
#'     \item{source_description, source_systems}{disclosure-ready source wording}
#'     \item{retired_cells}{cells retired by an earlier contract (see
#'       [urps_retired_values()])}
#'     \item{method_version, package_version}{producer + installed package versions}
#'   }
#' @seealso [urps_count()], [urps_lineage()], [validate_urps_ssot()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' urps_provenance()$canonical_2023_estimand
#' urps_provenance()[c("contract_version", "artifact_source", "canonical_release")]
#' @export
urps_provenance <- function() {
  r  <- .urps_resolve()
  m  <- .urps_manifest(r$dir)
  ct <- .urps_contract(r$dir)
  fl <- .urps_release_flags(r$dir, r$source)
  sf <- m$source_files
  src_sha <- m$combined_source_sha256 %||%
    (if (is.data.frame(sf)) sf$sha256[1]
     else if (is.list(sf) && length(sf)) sf[[1]]$sha256
     else m$source_sha256)
  list(
    artifact_version          = m$artifact_version,
    contract_version          = .urps_effective_contract_version(m, ct),
    artifact_source           = r$source,
    canonical_release         = fl$canonical_release,
    suitable_for_release      = fl$suitable_for_release,
    canonical_2023_estimand   = m$canonical_2023_estimand %||% (if (!is.null(ct)) ct$canonical_2023_estimand),
    external_artifact_error   = r$error,
    measure_years             = as.integer(m$measure_years),
    measures                  = m$measures,
    geographies               = m$geographies,
    snapshot_date             = as.Date(m$snapshot_date),
    roster_reflects_certifications_through = m$roster_reflects_certifications_through,
    boards                    = m$boards,
    geographic_scope          = m$geographic_scope,
    active_in_year_definition = m$active_in_year_definition,
    deduplication_rule        = m$deduplication_rule,
    source_sha256             = src_sha,
    source_git_commit         = m$git_commit %||% m$source_git_commit,
    git_commit_semantics      = m$git_commit_semantics,
    source_description        = m$source_description,
    source_systems            = m$source_systems,
    retired_cells             = m$retired_cells,
    method_version            = m$method_version,
    package_version           = as.character(utils::packageVersion("mufflyaccess"))
  )
}

#' URPS contract lineage (which cells are current vs retired)
#'
#' @description A machine-readable lineage of the 2023 board_certified_active
#'   national/CONUS cells across contract versions, built from the served
#'   artifact: the **current** headline (from the manifest) and any **retired**
#'   cells the producer recorded (`retired_cells`). Consumers use this to detect a
#'   value that was canonical under an old contract but must never be presented as
#'   current (e.g. v2.1.0's 1332/1329 after v3.0.0).
#' @details The `current` row comes from the served manifest's headline counts;
#'   the `retired` row(s) come from its `retired_cells` block. `basis` names the
#'   certification basis (e.g. URPS subspecialty cert vs primary board cert) that
#'   distinguishes the estimates. A consumer can screen a candidate value against
#'   the `retired` rows (or [urps_retired_values()]) to refuse presenting a stale
#'   count as current.
#' @return A `data.frame`, current row first, with columns:
#'   \describe{
#'     \item{contract_version}{e.g. `"3.0.0"` (current) / `"2.1.0"` (retired)}
#'     \item{national_active, conus_active}{the 2023 board_certified_active cells}
#'     \item{status}{`"current"` or `"retired"`}
#'     \item{basis}{the certification basis for that estimate}
#'   }
#' @seealso [urps_retired_values()], [urps_provenance()], [urps_count()]
#' @family URPS workforce
#' @examples
#' urps_lineage()
#' @export
urps_lineage <- function() {
  r <- .urps_resolve(); m <- .urps_manifest(r$dir)
  cur_v <- .urps_effective_contract_version(m, .urps_contract(r$dir))
  hc <- m$headline_counts$board_certified_active_2023
  rows <- data.frame(
    contract_version = as.character(cur_v),
    national_active  = as.integer(hc$national$combined),
    conus_active     = as.integer(hc$conus$combined),
    status           = "current",
    basis            = "URPS subspecialty cert year",
    stringsAsFactors = FALSE)
  rc <- m$retired_cells
  if (!is.null(rc) && !is.null(rc$v2_1_0_national)) {
    rows <- rbind(rows, data.frame(
      contract_version = "2.1.0",
      national_active  = as.integer(rc$v2_1_0_national),
      conus_active     = as.integer(rc$v2_1_0_conus),
      status           = "retired",
      basis            = "primary board cert year",
      stringsAsFactors = FALSE))
  }
  rows[order(rows$status != "current"), , drop = FALSE]
}

#' Values retired from an earlier URPS contract (never present as current)
#'
#' @description A flat integer vector of counts that were canonical under a prior
#'   contract and must **not** be presented as current. Use it as a guard in
#'   downstream code and manuscripts (e.g. fail a build if a figure caption
#'   contains one of these as "the 2023 count").
#' @return An integer vector of retired national/CONUS 2023 active counts (e.g.
#'   v2.1.0's 1332 / 1329), or `integer(0)` if the artifact records none.
#' @seealso [urps_lineage()], [urps_provenance()]
#' @family URPS workforce
#' @examples
#' urps_retired_values()
#' # a consumer-side guard:
#' stopifnot(!urps_count(2023, "board_certified_active", "national", TRUE) %in%
#'           urps_retired_values())
#' @export
urps_retired_values <- function() {
  rc <- .urps_manifest()$retired_cells
  if (is.null(rc)) return(integer(0))
  as.integer(stats::na.omit(c(rc$v2_1_0_national, rc$v2_1_0_conus)))
}

#' Validate a URPS workforce artifact directory (fail loud, semantic)
#'
#' @description Path-based contract check used before adopting an isochrones
#'   release. Verifies far more than a checksum: the contract version is
#'   supported, the counts table carries the `measure`/`geography` schema,
#'   each measure stays inside its declared year window, every measure/year/
#'   pathway is published for **both** geographies, `ABOG_PLUS_ABU` reconciles as
#'   `ABOG + ABU_NET_NEW`, hashes are well formed, the release-contract canonical
#'   cell agrees with the counts table, the CSV SHA-256 matches the manifest, and
#'   -- when a parquet reader is available -- the served counts reconstruct from
#'   the provider snapshot.
#' @details Checks performed, each failing loud with a specific message:
#'   \itemize{
#'     \item required files present; contract version valid, supported major, and
#'       consistent between manifest and release contract;
#'     \item the `measure x geography` schema, known measure/geography/pathway
#'       values, and each measure inside its declared year window;
#'     \item no duplicate keys; every `(measure, year)` cell present for **both**
#'       geographies and all three pathways;
#'     \item `ABOG_PLUS_ABU == ABOG + ABU_NET_NEW`; 64-hex `source_sha256`;
#'       manifest snapshot date consistent with the table;
#'     \item release-contract canonical cell agrees with the counts table;
#'     \item CSV SHA-256 matches the manifest;
#'     \item with a parquet reader, the served counts reconstruct from the
#'       provider snapshot (subspecialty-cert basis).
#'   }
#' @param path Directory holding `urps_counts_by_year.csv` + `urps_manifest.json`
#'   (and, optionally, `urps_release_contract.json` / the provider parquet).
#' @return Invisibly `TRUE`; otherwise stops with the failed check.
#' @seealso [use_urps_artifact()], [validate_urps_ssot()], [compare_urps_artifacts()]
#' @family URPS workforce
#' @examples
#' # the bundled artifact validates:
#' validate_urps_artifact(system.file("extdata", package = "mufflyaccess"))
#' @export
validate_urps_artifact <- function(path) {
  err <- .urps_dir_error(path)
  if (!is.null(err)) stop("[validate_urps_artifact] ", err, ": ", path, call. = FALSE)
  m  <- .urps_manifest(path)
  ct <- .urps_contract(path)

  # contract version: present, valid semver, supported major, and self-consistent
  cv <- .urps_effective_contract_version(m, ct)
  if (is.null(cv) || is.na(cv))
    stop("[validate_urps_artifact] missing contract_version / artifact_version.", call. = FALSE)
  sv <- .urps_semver(cv)
  if (is.null(sv))
    stop(sprintf("[validate_urps_artifact] invalid semantic version '%s'.", cv), call. = FALSE)
  if (!sv[1] %in% .urps_contract_majors)
    stop(sprintf("[validate_urps_artifact] unsupported contract version %s (supported major: %s).",
                 cv, paste(.urps_contract_majors, collapse = ", ")), call. = FALSE)
  if (!is.null(m$contract_version) && !is.null(ct) && !is.null(ct$contract_version) &&
      !identical(as.character(m$contract_version), as.character(ct$contract_version)))
    stop(sprintf("[validate_urps_artifact] manifest and release-contract versions disagree (%s vs %s).",
                 m$contract_version, ct$contract_version), call. = FALSE)

  d <- .urps_read_long(path)
  req <- c("year", "measure", "geography", "board_pathway", "n_active",
           "snapshot_date", "source_sha256", "method_version")
  if (!all(req %in% names(d)))
    stop("[validate_urps_artifact] counts table is missing required columns; ",
         "the measure x geography schema needs measure + geography (fused-geography contracts are unsupported schema).",
         call. = FALSE)
  if (!all(d$geography %in% .urps_geographies))
    stop("[validate_urps_artifact] unknown geography value(s): ",
         paste(setdiff(unique(d$geography), .urps_geographies), collapse = ", "), call. = FALSE)
  if (!all(d$measure %in% .urps_measures))
    stop("[validate_urps_artifact] unknown measure value(s): ",
         paste(setdiff(unique(d$measure), .urps_measures), collapse = ", "), call. = FALSE)
  if (!all(d$board_pathway %in% .urps_pathways))
    stop("[validate_urps_artifact] unknown board_pathway value(s): ",
         paste(setdiff(unique(d$board_pathway), .urps_pathways), collapse = ", "), call. = FALSE)

  # temporal windows
  bca <- d[d$measure == "board_certified_active", ]
  if (nrow(bca) && !setequal(unique(bca$year), .urps_bca_years))
    stop(sprintf("[validate_urps_artifact] board_certified_active must cover %d-%d exactly (got %s).",
                 min(.urps_bca_years), max(.urps_bca_years),
                 paste(sort(unique(bca$year)), collapse = ", ")), call. = FALSE)
  ros <- d[d$measure == "roster_snapshot", ]
  if (nrow(ros) && !all(ros$year == .urps_snapshot_year))
    stop(sprintf("[validate_urps_artifact] roster_snapshot must be year %d only.",
                 .urps_snapshot_year), call. = FALSE)

  # no duplicate count keys
  kd <- paste(d$year, d$measure, d$geography, d$board_pathway, sep = "|")
  if (anyDuplicated(kd))
    stop("[validate_urps_artifact] duplicate count key (year/measure/geography/board_pathway).",
         call. = FALSE)

  # per-cell pathway completeness: every (measure,year,geography) needs all three
  # pathways (missing a pathway row would silently break reconciliation).
  cells <- unique(d[, c("year", "measure", "geography")])
  for (i in seq_len(nrow(cells))) {
    sel <- d$year == cells$year[i] & d$measure == cells$measure[i] &
           d$geography == cells$geography[i]
    if (!all(.urps_pathways %in% d$board_pathway[sel]))
      stop(sprintf("[validate_urps_artifact] missing pathway row for %s/%s/%d (need %s).",
                   cells$measure[i], cells$geography[i], cells$year[i],
                   paste(.urps_pathways, collapse = ", ")), call. = FALSE)
  }

  # snapshot date consistency between manifest and counts table
  if (!is.null(m$snapshot_date) &&
      !(as.character(m$snapshot_date) %in% as.character(unique(d$snapshot_date))))
    stop("[validate_urps_artifact] manifest snapshot_date does not match the counts table.",
         call. = FALSE)

  # geography completeness: every (measure,year,pathway) in one geography must
  # exist in both -- mufflyaccess must never derive CONUS from national.
  key <- function(g) unique(paste(d$measure[d$geography == g], d$year[d$geography == g],
                                   d$board_pathway[d$geography == g], sep = "|"))
  kn <- key("national"); kc <- key("conus")
  if (!setequal(kn, kc)) {
    only_nat <- setdiff(kn, kc); only_con <- setdiff(kc, kn)
    ex <- c(only_nat, only_con)[1] %||% "n/a"
    stop(sprintf("[validate_urps_artifact] incomplete geography coverage: national and conus cells differ (missing conus: %d, missing national: %d; e.g. %s).",
                 length(only_nat), length(only_con), ex), call. = FALSE)
  }

  # reconciliation ABOG_PLUS_ABU == ABOG + ABU_NET_NEW within (year,measure,geography)
  w <- stats::reshape(d[, c("year", "measure", "geography", "board_pathway", "n_active")],
                      idvar = c("year", "measure", "geography"),
                      timevar = "board_pathway", direction = "wide")
  cn <- function(p) w[[paste0("n_active.", p)]]
  ok <- is.na(cn("ABOG_PLUS_ABU")) | is.na(cn("ABOG")) | is.na(cn("ABU_NET_NEW")) |
        (cn("ABOG_PLUS_ABU") == cn("ABOG") + cn("ABU_NET_NEW"))
  if (!all(ok))
    stop("[validate_urps_artifact] ABOG_PLUS_ABU does not reconcile as ABOG + ABU_NET_NEW ",
         "(semantic/provider mismatch).", call. = FALSE)

  sh <- d$source_sha256[!is.na(d$source_sha256)]
  if (!all(grepl("^[0-9a-f]{64}$", sh)))
    stop("[validate_urps_artifact] malformed source_sha256 (each must be 64-hex).", call. = FALSE)

  # release-contract canonical cell must agree with the counts table
  if (!is.null(ct) && !is.null(ct$canonical)) {
    cc <- ct$canonical
    served <- d$n_active[d$year == as.integer(cc$year) & d$measure == cc$measure &
                         d$geography == cc$geography & d$board_pathway == cc$board_pathway]
    if (length(served) != 1L || served != as.integer(cc$n_active))
      stop(sprintf("[validate_urps_artifact] release-contract canonical cell (%s) disagrees with the counts table (served %s).",
                   cc$n_active, if (length(served)) served else "missing"), call. = FALSE)
  }

  # CSV SHA-256 vs manifest
  if (requireNamespace("digest", quietly = TRUE)) {
    expected <- m$artifact_sha256 %||% m$output_files$urps_counts_by_year_csv$sha256
    if (!is.null(expected)) {
      got <- digest::digest(file = .urps_path("urps_counts_by_year.csv", path), algo = "sha256")
      if (!identical(got, expected))
        stop("[validate_urps_artifact] counts CSV SHA-256 does not match the manifest.", call. = FALSE)
    }
  }

  # provider reconstruction (when a parquet reader is available)
  reader <- .urps_parquet_reader()
  pq <- file.path(path, "urps_provider_snapshot.parquet")
  if (!is.null(reader) && file.exists(pq)) {
    pv <- reader(pq)
    # v3.0.0 keys board_certified_active on the URPS SUBSPECIALTY cert year
    # (training-accurate); v2.x used the primary certification_year. Reconstruct
    # on whichever basis this artifact ships.
    cert_col <- if ("urps_subspecialty_cert_year" %in% names(pv)) "urps_subspecialty_cert_year"
                else "certification_year"
    if (all(c(cert_col, "retirement_year") %in% names(pv))) {
      cy <- suppressWarnings(as.integer(pv[[cert_col]]))
      ry <- suppressWarnings(as.integer(pv$retirement_year))
      active <- !is.na(cy) & cy <= 2023L & (is.na(ry) | ry > 2023L)
      served_nat <- d$n_active[d$year == 2023L & d$measure == "board_certified_active" &
                               d$geography == "national" & d$board_pathway == "ABOG_PLUS_ABU"]
      if (length(served_nat) == 1L && sum(active) != served_nat)
        stop(sprintf("[validate_urps_artifact] provider reconstruction: active_2023 national (%d) != served count (%d) -- certification/temporal mismatch.",
                     sum(active), served_nat), call. = FALSE)
      if ("is_conus" %in% names(pv)) {
        served_conus <- d$n_active[d$year == 2023L & d$measure == "board_certified_active" &
                                   d$geography == "conus" & d$board_pathway == "ABOG_PLUS_ABU"]
        if (length(served_conus) == 1L && sum(active & as.logical(pv$is_conus)) != served_conus)
          stop(sprintf("[validate_urps_artifact] provider reconstruction: active_2023 conus (%d) != served count (%d).",
                       sum(active & as.logical(pv$is_conus)), served_conus), call. = FALSE)
      }
      served_snap <- d$n_active[d$year == 2025L & d$measure == "roster_snapshot" &
                                d$geography == "national" & d$board_pathway == "ABOG_PLUS_ABU"]
      if (length(served_snap) == 1L && nrow(pv) != served_snap)
        stop(sprintf("[validate_urps_artifact] provider snapshot rows (%d) != served roster_snapshot (%d).",
                     nrow(pv), served_snap), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Validate the URPS workforce SSOT (fail loud)
#'
#' @description With no `counts`, validates the active artifact end to end via
#'   [validate_urps_artifact()] and enforces the requested release gates. With a
#'   wide `counts` `data.frame` (as from [urps_counts()]), checks that table's
#'   schema, unique + complete 2013-2023 years, 64-hex hashes, and the
#'   `combined_active == abog_active + abu_net_new` identity.
#' @param counts Optional wide counts `data.frame`; `NULL` (default) validates the
#'   active artifact.
#' @param require_external If `TRUE`, require an external released artifact (not
#'   the bundled bootstrap).
#' @param require_canonical If `TRUE`, require `canonical_release`.
#' @param require_contract_version Optional exact contract version string to require.
#' @param require_source_git_commit Optional exact source git commit to require.
#' @return Invisibly `TRUE`; otherwise stops with the failed check.
#' @seealso [validate_urps_artifact()], [urps_provenance()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' validate_urps_ssot()                     # the active artifact
#' validate_urps_ssot(urps_counts())        # a wide counts table
#' # release gate (errors on the bundled bootstrap):
#' try(validate_urps_ssot(require_external = TRUE, require_contract_version = "3.0.0"))
#' @export
validate_urps_ssot <- function(counts = NULL, require_external = FALSE,
                               require_canonical = FALSE,
                               require_contract_version = NULL,
                               require_source_git_commit = NULL) {
  if (isTRUE(require_external)) {
    r <- .urps_resolve()
    if (!identical(r$source, "external"))
      stop("[validate] require_external = TRUE but the active artifact is the bundled ",
           "bootstrap (not a canonical release); call use_urps_artifact('<released dir>') first.",
           call. = FALSE)
  }
  if (!is.null(counts)) return(.urps_validate_wide(counts))

  validate_urps_artifact(.urps_artifact_dir())
  p <- urps_provenance()
  if (isTRUE(require_canonical) && !isTRUE(p$canonical_release))
    stop("[validate] require_canonical = TRUE but the active artifact is not a canonical release.",
         call. = FALSE)
  if (!is.null(require_contract_version) &&
      !identical(as.character(p$contract_version), as.character(require_contract_version)))
    stop(sprintf("[validate] contract version %s does not match the required %s.",
                 p$contract_version, require_contract_version), call. = FALSE)
  if (!is.null(require_source_git_commit) &&
      !identical(as.character(p$source_git_commit), as.character(require_source_git_commit)))
    stop(sprintf("[validate] source git commit %s does not match the required %s.",
                 p$source_git_commit, require_source_git_commit), call. = FALSE)
  invisible(TRUE)
}

.urps_validate_wide <- function(w) {
  req <- c("year", "abog_active", "abu_net_new", "combined_active", "source_sha256")
  if (!all(req %in% names(w)))
    stop("[validate] counts table is missing required columns.", call. = FALSE)
  if (anyDuplicated(w$year))
    stop("[validate] measure years must be unique (duplicate year found).", call. = FALSE)
  miss <- setdiff(.urps_bca_years, w$year)
  if (length(miss))
    stop(sprintf("[validate] missing measure year(s) %s; the series must cover 2013:2023.",
                 paste(miss, collapse = ", ")), call. = FALSE)
  sh <- w$source_sha256[!is.na(w$source_sha256)]
  if (!all(grepl("^[0-9a-f]{64}$", sh)))
    stop("[validate] malformed source_sha256 (each must be a 64-character hex hash).", call. = FALSE)
  ok <- is.na(w$combined_active) | is.na(w$abu_net_new) |
        (w$combined_active == w$abog_active + w$abu_net_new)
  if (!all(ok))
    stop("[validate] combined_active must reconcile as abog_active + abu_net_new.", call. = FALSE)
  invisible(TRUE)
}

#' Compare two URPS workforce artifacts (release-to-release drift)
#'
#' @description Structured diff of two artifact directories: provider additions /
#'   removals (by NPI, when the provider parquet is readable), changed
#'   certification years, changed geography assignments, changed pathway
#'   assignments, and changed count cells. A non-empty diff means the candidate
#'   release must not be adopted without reviewed, accepted drift.
#' @param old,candidate Artifact directories to compare (`old` = current,
#'   `candidate` = proposed).
#' @return A named list; provider-level fields are populated only when the
#'   provider parquet is readable (arrow / nanoparquet):
#'   \describe{
#'     \item{added_providers, removed_providers}{NPIs gained / dropped}
#'     \item{changed_certification_year, changed_geography, changed_pathway}{
#'       NPIs whose attribute changed}
#'     \item{changed_counts}{`year|measure|geography|pathway` keys whose count
#'       changed}
#'   }
#' @seealso [validate_urps_artifact()], [use_urps_artifact()]
#' @family URPS workforce
#' @examples
#' \dontrun{
#' drift <- compare_urps_artifacts("artifacts/v3.0.0", "artifacts/candidate")
#' if (length(drift$changed_counts)) stop("counts changed; review before adopting")
#' }
#' @export
compare_urps_artifacts <- function(old, candidate) {
  co <- .urps_read_long(old); cc <- .urps_read_long(candidate)
  key <- function(x) paste(x$year, x$measure, x$geography, x$board_pathway, sep = "|")
  ko <- stats::setNames(co$n_active, key(co)); kc <- stats::setNames(cc$n_active, key(cc))
  shared <- intersect(names(ko), names(kc))
  changed_counts <- shared[ko[shared] != kc[shared]]

  added <- removed <- changed_cert <- changed_geo <- changed_path <- character(0)
  reader <- .urps_parquet_reader()
  po <- file.path(old, "urps_provider_snapshot.parquet")
  pc <- file.path(candidate, "urps_provider_snapshot.parquet")
  if (!is.null(reader) && file.exists(po) && file.exists(pc)) {
    a <- reader(po); b <- reader(pc)
    if ("npi" %in% names(a) && "npi" %in% names(b)) {
      added   <- setdiff(b$npi, a$npi)
      removed <- setdiff(a$npi, b$npi)
      common  <- intersect(a$npi, b$npi)
      ia <- match(common, a$npi); ib <- match(common, b$npi)
      chg <- function(col) if (col %in% names(a) && col %in% names(b))
        common[which(as.character(a[[col]][ia]) != as.character(b[[col]][ib]))] else character(0)
      changed_cert <- chg("certification_year")
      changed_geo  <- chg("is_conus")
      changed_path <- chg("board_pathway")
    }
  }
  list(added_providers = added, removed_providers = removed,
       changed_certification_year = changed_cert, changed_geography = changed_geo,
       changed_pathway = changed_path, changed_counts = changed_counts)
}
