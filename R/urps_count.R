# Fingerprint of the isochrones ABOG workforce snapshot
# (manuscript/tables/table1_physician_characteristics.csv) that the ABOG-active
# 1,031 was computed from. The ABU pathway (+308) is a separate cliff roster.
# See ARCHITECTURE.md: isochrones owns the snapshot; mufflyaccess only validates
# it and returns counts -- it never re-cleans providers.
.URPS_ABOG_SNAPSHOT_SHA256 <-
  "5f1b6167fad81ba896c0b1bc1ceda8eb966e681f51b176105b389a27399e0c0f"

#' National URPS workforce count -- the stable SSOT interface
#'
#' @description Returns the single-source-of-truth active URPS (urogynecology and
#'   reconstructive pelvic surgery) national workforce count, with its metadata
#'   and provenance. This is the interface `cliff` / `twostep` / manuscripts /
#'   apps should call: **never hardcode or independently derive a national URPS
#'   count** -- call `urps_count()`.
#'
#'   Per the repository architecture (see `ARCHITECTURE.md`), provider cleaning
#'   (rosters, certification, retirement, NPI matching, dedup) and the immutable
#'   hashed workforce snapshot are owned by `isochrones`. `mufflyaccess` owns the
#'   definitions and this interface and contains **no alternative
#'   provider-cleaning pipeline** -- this function does not re-derive rosters. It
#'   returns the reconciled count plus the fingerprint of the snapshot it was
#'   computed from, and (optionally) validates a supplied snapshot against that
#'   fingerprint.
#' @param definition Which cohort: `"abog_plus_abu"` (default; WITH the urology
#'   pathway) or `"abog"` (WITHOUT urology, OB/GYN pathway only).
#' @param snapshot Optional path to the isochrones ABOG workforce snapshot
#'   (`table1_physician_characteristics.csv`). If supplied, its SHA-256 is checked
#'   against the fingerprint this baseline was computed from and the call **errors
#'   loudly on a mismatch** (needs the `digest` package). If `NULL` (default) the
#'   cached reconciled value is returned with `validated = FALSE`.
#' @return An integer count carrying attributes `definition`, `year`, `urology`,
#'   `cohort`, `source`, `abog_snapshot_sha256`, and `validated`. It is a plain
#'   integer, so it can be used directly in arithmetic while the provenance rides
#'   along in its attributes.
#' @seealso [URPS_COUNT_ABOG_ONLY_2025], [URPS_COUNT_ABOG_PLUS_ABU_2025]; the
#'   by-year reference derivation in `analysis/urps_counts/`.
#' @family URPS workforce
#' @examples
#' urps_count()             # 1339  (with urology)
#' urps_count("abog")       # 1031  (without urology)
#' as.integer(urps_count()) # 1339, bare
#' attr(urps_count(), "source")
#' @export
urps_count <- function(definition = c("abog_plus_abu", "abog"), snapshot = NULL) {
  definition <- match.arg(definition)
  value <- switch(definition,
                  abog          = URPS_COUNT_ABOG_ONLY_2025,
                  abog_plus_abu = URPS_COUNT_ABOG_PLUS_ABU_2025)

  validated <- FALSE
  if (!is.null(snapshot)) {
    if (!file.exists(snapshot))
      stop("[urps_count] snapshot not found: ", snapshot, call. = FALSE)
    if (!requireNamespace("digest", quietly = TRUE))
      stop("[urps_count] validating a snapshot needs the 'digest' package ",
           "(install.packages(\"digest\")).", call. = FALSE)
    got <- digest::digest(file = snapshot, algo = "sha256")
    if (!identical(got, .URPS_ABOG_SNAPSHOT_SHA256))
      stop("[urps_count] supplied snapshot does not match the fingerprint this ",
           "baseline was computed from -- it is not the isochrones snapshot ",
           "behind the SSOT count.\n  expected: ", .URPS_ABOG_SNAPSHOT_SHA256,
           "\n  supplied: ", got, call. = FALSE)
    validated <- TRUE
  }

  structure(
    as.integer(value),
    definition           = definition,
    year                 = 2025L,
    urology              = if (definition == "abog_plus_abu") "with" else "without",
    cohort               = attr(value, "cohort"),
    source               = attr(value, "source"),
    abog_snapshot_sha256 = .URPS_ABOG_SNAPSHOT_SHA256,
    validated            = validated
  )
}
