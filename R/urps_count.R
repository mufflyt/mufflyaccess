# ==============================================================================
# The published URPS workforce SSOT interface.
#
# Per ARCHITECTURE.md: isochrones builds the provider roster and publishes the
# hashed workforce artifacts; mufflyaccess reads + validates them and serves the
# number; cliff / twostep / manuscripts / apps call these functions and never
# derive a national URPS count themselves.
#
# mufflyaccess ships a COMPACT canonical table (inst/extdata/urps_counts_by_year.csv)
# and its manifest (inst/extdata/urps_manifest.json). This is currently a
# BOOTSTRAP of what isochrones will publish as
# artifacts/workforce/urps_counts_by_year.csv + urps_manifest.json; when that
# versioned release exists, these readers point at it instead. mufflyaccess never
# rebuilds provider rosters.
# ==============================================================================

.urps_extdata <- function(file) {
  p <- system.file("extdata", file, package = "mufflyaccess")
  if (!nzchar(p)) p <- file.path("inst", "extdata", file)  # dev (load_all) fallback
  p
}

.urps_read_counts <- function() {
  utils::read.csv(
    .urps_extdata("urps_counts_by_year.csv"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"),
    colClasses = c(year = "integer", board_pathway = "character",
                   n_active = "integer", n_ever_certified = "integer",
                   n_retired = "integer", snapshot_date = "character",
                   source_sha256 = "character", method_version = "character")
  )
}

.urps_read_manifest <- function() {
  jsonlite::fromJSON(.urps_extdata("urps_manifest.json"), simplifyVector = TRUE)
}

#' National URPS workforce count -- the published SSOT interface
#'
#' @description The single-source-of-truth accessor for the national active URPS
#'   (urogynecology and reconstructive pelvic surgery) workforce count. This is
#'   what `cliff` / `twostep` / manuscripts / apps call -- **never hardcode or
#'   independently derive a national URPS count** (see `ARCHITECTURE.md`).
#'
#'   Three distinct years travel with every number and must not be conflated:
#'   the **measure year** (`year`, what the count refers to), the **snapshot
#'   date** (when the underlying roster was extracted, e.g. 2026-07-22), and the
#'   **model baseline year** (the workforce-model label, e.g. 2025). They are
#'   returned as separate attributes.
#' @param year Integer measure year (default `2023L`). ABOG-only is available
#'   2013-2023; the with-urology (ABU) cohort is a 2023 snapshot only.
#' @param include_urology Logical. `FALSE` (default) = ABOG / OB-GYN pathway
#'   only (WITHOUT urology); `TRUE` = both-pathway ABOG + ABU (WITH urology).
#' @return An integer `n_active` count carrying attributes `measure_year`,
#'   `board_pathway`, `include_urology`, `n_ever_certified`, `n_retired`,
#'   `snapshot_date`, `model_baseline_year`, `source_sha256`, `method_version`,
#'   and a one-line `provenance` string. It is a plain integer, usable directly
#'   in arithmetic, with provenance riding along in its attributes.
#' @seealso [urps_counts()], [urps_provenance()], [validate_urps_ssot()]
#' @family URPS workforce
#' @examples
#' urps_count(2023L, include_urology = FALSE)  # 1031  (without urology)
#' urps_count(2023L, include_urology = TRUE)   # 1339  (with urology)
#' attr(urps_count(2023L), "snapshot_date")
#' @export
urps_count <- function(year = 2023L, include_urology = FALSE) {
  stopifnot(length(year) == 1L, length(include_urology) == 1L,
            is.logical(include_urology), !is.na(include_urology))
  year    <- as.integer(year)
  pathway <- if (include_urology) "abog_plus_abu" else "abog"
  tab     <- .urps_read_counts()
  row     <- tab[tab$year == year & tab$board_pathway == pathway, , drop = FALSE]
  if (nrow(row) != 1L) {
    avail <- sort(unique(tab$year[tab$board_pathway == pathway]))
    stop(sprintf("[urps_count] no %s count for measure year %d (available: %s).%s",
                 pathway, year, paste(avail, collapse = ", "),
                 if (include_urology)
                   " The with-urology (ABU) cohort is a 2023 snapshot only." else ""),
         call. = FALSE)
  }
  man <- .urps_read_manifest()
  structure(
    row$n_active,
    measure_year        = year,
    board_pathway       = pathway,
    include_urology     = include_urology,
    n_ever_certified    = row$n_ever_certified,
    n_retired           = row$n_retired,
    snapshot_date       = row$snapshot_date,
    model_baseline_year = as.integer(man$years$model_baseline_year),
    source_sha256       = row$source_sha256,
    method_version      = row$method_version,
    provenance          = sprintf(
      "mufflyaccess SSOT | measure_year=%d | snapshot_date=%s | model_baseline_year=%s | pathway=%s",
      year, row$snapshot_date, man$years$model_baseline_year, pathway)
  )
}

#' The full canonical URPS workforce table
#'
#' @description Returns the compact canonical workforce table `mufflyaccess`
#'   ships: one row per (measure year x board pathway), with `n_active`,
#'   `n_ever_certified`, `n_retired`, `snapshot_date`, `source_sha256`, and
#'   `method_version`. Board pathways: `"abog"` (2013-2023), `"abu"` (2023
#'   net-new snapshot), `"abog_plus_abu"` (2023 combined).
#' @return A `data.frame`.
#' @seealso [urps_count()], [urps_provenance()], [validate_urps_ssot()]
#' @family URPS workforce
#' @examples
#' head(urps_counts())
#' subset(urps_counts(), board_pathway == "abog_plus_abu")
#' @export
urps_counts <- function() .urps_read_counts()

#' Provenance / manifest for the URPS workforce SSOT
#'
#' @description Returns the manifest for the canonical table: source files and
#'   SHA-256 hashes, snapshot date, the active-in-year definition, the ABOG/ABU
#'   deduplication rule, geographic scope, known limitations, and provenance git
#'   SHAs. Every returned count traces back to this.
#' @return A named list (parsed from `inst/extdata/urps_manifest.json`).
#' @seealso [urps_count()], [validate_urps_ssot()]
#' @family URPS workforce
#' @examples
#' urps_provenance()$years
#' urps_provenance()$known_limitations
#' @export
urps_provenance <- function() .urps_read_manifest()

#' Validate the URPS workforce SSOT (fail loud)
#'
#' @description Checks the shipped canonical table against its manifest and the
#'   frozen contract: schema, the reconciled headline values (2023 ABOG = 1031,
#'   ABOG+ABU = 1339, ABU net-new = 308), the reconciliation identity
#'   (`abog_plus_abu = abog + abu`), the contiguous 2013-2023 ABOG series,
#'   agreement of the deprecated `*_2025` constants with the table, and (when
#'   `digest` is installed) the table's SHA-256 against the manifest. Errors on
#'   any violation.
#' @return Invisibly `TRUE` on success; otherwise stops with the failed check.
#' @seealso [urps_count()], [urps_counts()], [urps_provenance()]
#' @family URPS workforce
#' @examples
#' validate_urps_ssot()
#' @export
validate_urps_ssot <- function() {
  tab <- .urps_read_counts()
  man <- .urps_read_manifest()
  need <- c("year", "board_pathway", "n_active", "n_ever_certified",
            "n_retired", "snapshot_date", "source_sha256", "method_version")
  pick <- function(y, p) {
    v <- tab$n_active[tab$year == y & tab$board_pathway == p]
    if (length(v) == 1L) v else NA_integer_
  }
  abog23 <- pick(2023L, "abog"); abu23 <- pick(2023L, "abu")
  comb23 <- pick(2023L, "abog_plus_abu")
  stopifnot(
    "[validate] canonical table is missing required columns" = all(need %in% names(tab)),
    "[validate] 2023 ABOG-only must be 1031"                  = identical(abog23, 1031L),
    "[validate] 2023 ABOG+ABU (with urology) must be 1339"    = identical(comb23, 1339L),
    "[validate] 2023 ABU net-new must be 308"                 = identical(abu23, 308L),
    "[validate] reconciliation must hold: abog_plus_abu == abog + abu" =
      identical(comb23, abog23 + abu23),
    "[validate] ABOG series must be the contiguous 2013-2023 years" =
      identical(sort(tab$year[tab$board_pathway == "abog"]), 2013:2023),
    "[validate] deprecated URPS_COUNT_ABOG_ONLY_2025 must equal the table" =
      identical(as.integer(URPS_COUNT_ABOG_ONLY_2025), abog23),
    "[validate] deprecated URPS_COUNT_ABOG_PLUS_ABU_2025 must equal the table" =
      identical(as.integer(URPS_COUNT_ABOG_PLUS_ABU_2025), comb23)
  )
  if (requireNamespace("digest", quietly = TRUE)) {
    got <- digest::digest(file = .urps_extdata("urps_counts_by_year.csv"), algo = "sha256")
    if (!identical(got, man$artifact_sha256))
      stop("[validate] canonical table SHA-256 does not match the manifest.\n",
           "  manifest: ", man$artifact_sha256, "\n  actual:   ", got, call. = FALSE)
  }
  message("URPS SSOT OK: 2023 without urology = 1031, with urology = 1339 ",
          "(ABU net-new 308); table matches manifest.")
  invisible(TRUE)
}
