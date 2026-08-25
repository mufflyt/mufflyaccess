# ==============================================================================
# Frozen isochrone SSOT: served by hash, never by path.
#
# The E2SFCA primary analysis was computed against ONE isochrone set. At least
# three near-identical sets exist on the author's machines with the same file
# names, the same four bands and similar sizes. The wrong one has 3,909 origins
# against the right one's 4,050, and the 141 it lacks include 44 physician
# locations. Used unknowingly it does not error -- it silently drops those
# providers' supply and deflates access by up to 3.7%.
#
# Nothing about a path tells you which set you have. Only the hash does, so this
# interface refuses to hand back a directory it has not verified.
#
# Resolution order:
#   1. use_frozen_isochrones("<dir>")      explicit adoption, fails closed
#   2. option  mufflyaccess.frozen_isochrones_dir
#   3. env     MUFFLYACCESS_FROZEN_ISOCHRONES_DIR
#   4. env     E2SFCA_ISO_DIR                       (compatibility)
#
# The payload is 1.4 GB and is NOT bundled. Only the checksum manifest ships.
# Canonical copies: S3 and Dropbox, both recorded in ssot_sources.json.
# ==============================================================================

.ssot_dir <- function() {
  d <- system.file("extdata", "ssot", package = "mufflyaccess")
  if (nzchar(d)) d else file.path("inst", "extdata", "ssot")
}

.frozen_iso_manifest <- function() {
  f <- file.path(.ssot_dir(), "frozen_isochrones.sha256")
  if (!file.exists(f)) stop("frozen isochrone manifest missing from the package", call. = FALSE)
  x <- readLines(f, warn = FALSE)
  x <- x[!grepl("^\\s*#", x) & nzchar(trimws(x))]
  parts <- strsplit(trimws(x), "\\s+")
  stats::setNames(vapply(parts, `[`, character(1), 1L),
                  vapply(parts, function(p) p[length(p)], character(1)))
}

.frozen_iso_env <- new.env(parent = emptyenv())

#' Verify a directory holds the frozen isochrone set
#'
#' Hashes every band and compares against the manifest shipped with the package.
#' @param dir Directory to check.
#' @param quiet Suppress the per-band report.
#' @return `TRUE` invisibly if every band matches; otherwise an error naming the
#'   bands that differ.
#' @export
verify_frozen_isochrones <- function(dir, quiet = FALSE) {
  if (!requireNamespace("digest", quietly = TRUE))
    stop("verify_frozen_isochrones() needs the 'digest' package", call. = FALSE)
  want <- .frozen_iso_manifest()
  if (is.null(dir) || !nzchar(dir) || !dir.exists(dir))
    stop("not a directory: ", dir %||% "<NULL>", call. = FALSE)
  bad <- character(0); missing <- character(0)
  for (nm in names(want)) {
    f <- file.path(dir, nm)
    if (!file.exists(f)) { missing <- c(missing, nm); next }
    got <- digest::digest(file = f, algo = "sha256")
    if (!identical(got, unname(want[[nm]]))) bad <- c(bad, nm)
    else if (!quiet) message(sprintf("  verified %s", nm))
  }
  if (length(missing) || length(bad))
    stop("this is NOT the frozen isochrone set.\n",
         if (length(missing)) paste0("  absent: ", paste(missing, collapse = ", "), "\n") else "",
         if (length(bad)) paste0("  hash differs: ", paste(bad, collapse = ", "), "\n") else "",
         "  A set with the same names and 3,909 origins exists and is missing 44\n",
         "  physician locations. See mufflyaccess::frozen_isochrones_provenance().",
         call. = FALSE)
  invisible(TRUE)
}

#' Adopt a directory as the frozen isochrone SSOT
#'
#' Verifies before adopting, so an invalid directory can never become the source.
#' @param dir Directory holding the four consolidated isochrone files.
#' @return The adopted path, invisibly.
#' @export
use_frozen_isochrones <- function(dir) {
  verify_frozen_isochrones(dir, quiet = TRUE)
  assign("dir", normalizePath(dir), envir = .frozen_iso_env)
  message("frozen isochrones adopted: ", normalizePath(dir))
  invisible(normalizePath(dir))
}

#' Path to the verified frozen isochrone set
#'
#' @param verify Re-hash before returning (default `TRUE`).
#' @return Directory path. Errors if no verified set can be resolved.
#' @export
frozen_isochrones_dir <- function(verify = TRUE) {
  cand <- c(
    get0("dir", envir = .frozen_iso_env, ifnotfound = NULL),
    getOption("mufflyaccess.frozen_isochrones_dir"),
    Sys.getenv("MUFFLYACCESS_FROZEN_ISOCHRONES_DIR", ""),
    Sys.getenv("E2SFCA_ISO_DIR", ""))
  cand <- unique(cand[!vapply(cand, function(z) is.null(z) || !nzchar(z), logical(1))])
  if (!length(cand))
    stop("no frozen isochrone directory configured.\n",
         "  Set one with use_frozen_isochrones(\"<dir>\"), or fetch the canonical\n",
         "  copy listed in mufflyaccess::frozen_isochrones_provenance().", call. = FALSE)
  for (d in cand) {
    ok <- tryCatch({ if (verify) verify_frozen_isochrones(d, quiet = TRUE); TRUE },
                   error = function(e) FALSE)
    if (ok) return(d)
  }
  stop("none of the configured directories holds the frozen isochrone set:\n  ",
       paste(cand, collapse = "\n  "),
       "\n  Verified by hash, not by name -- see verify_frozen_isochrones().", call. = FALSE)
}

#' Provenance of the frozen isochrone SSOT
#' @return A list describing the canonical copies and why the hash gate exists.
#' @export
frozen_isochrones_provenance <- function() {
  f <- file.path(.ssot_dir(), "ssot_sources.json")
  src <- if (file.exists(f) && requireNamespace("jsonlite", quietly = TRUE))
    jsonlite::fromJSON(f)$frozen_isochrones else list()
  resolved <- tryCatch(frozen_isochrones_dir(verify = TRUE), error = function(e) NA_character_)
  c(list(checksums = .frozen_iso_manifest(),
         resolved_dir = resolved,
         verified = !is.na(resolved)), src)
}
