# ==============================================================================
# ABOG certification-registry refresh SSOT.
#
# refresh_merged.csv is the 79,398-row scraped ABOG registry that downstream
# cohorts are built from. Served here so consumers read ONE verified copy rather
# than whichever CSV happens to be in a Downloads folder.
#
# 9 MB is too large to bundle usefully and small enough that a stale copy is easy
# to acquire, so the same discipline as the isochrones applies: the checksum
# ships, the payload does not, and the reader refuses a file whose hash does not
# match.
#
# Resolution order:
#   1. use_abog_refresh("<path>")     explicit adoption, fails closed
#   2. option  mufflyaccess.abog_refresh_path
#   3. env     MUFFLYACCESS_ABOG_REFRESH
# ==============================================================================

.abog_env <- new.env(parent = emptyenv())

.abog_expected_sha <- function() {
  f <- file.path(.ssot_dir(), "abog_refresh.sha256")
  if (!file.exists(f)) stop("ABOG refresh manifest missing from the package", call. = FALSE)
  trimws(strsplit(readLines(f, warn = FALSE)[1], "\\s+")[[1]][1])
}

#' Verify a file is the canonical ABOG registry refresh
#' @param path Path to refresh_merged.csv.
#' @return `TRUE` invisibly, or an error showing both hashes.
#' @export
verify_abog_refresh <- function(path) {
  if (!requireNamespace("digest", quietly = TRUE))
    stop("verify_abog_refresh() needs the 'digest' package", call. = FALSE)
  if (!file.exists(path)) stop("file not found: ", path, call. = FALSE)
  want <- .abog_expected_sha()
  got  <- digest::digest(file = path, algo = "sha256")
  if (!identical(got, want))
    stop("this is not the canonical ABOG registry refresh.\n",
         "  expected sha256: ", want, "\n",
         "  file sha256    : ", got, "\n",
         "  Fetch the canonical copy -- see abog_refresh_provenance().", call. = FALSE)
  invisible(TRUE)
}

#' Adopt a file as the ABOG registry SSOT
#' @param path Path to refresh_merged.csv.
#' @return The adopted path, invisibly.
#' @export
use_abog_refresh <- function(path) {
  verify_abog_refresh(path)
  assign("path", normalizePath(path), envir = .abog_env)
  message("ABOG registry refresh adopted: ", normalizePath(path))
  invisible(normalizePath(path))
}

#' Path to the verified ABOG registry refresh
#' @param verify Re-hash before returning (default `TRUE`).
#' @return File path. Errors if none can be resolved and verified.
#' @export
abog_refresh_path <- function(verify = TRUE) {
  cand <- c(get0("path", envir = .abog_env, ifnotfound = NULL),
            getOption("mufflyaccess.abog_refresh_path"),
            Sys.getenv("MUFFLYACCESS_ABOG_REFRESH", ""))
  cand <- unique(cand[!vapply(cand, function(z) is.null(z) || !nzchar(z), logical(1))])
  if (!length(cand))
    stop("no ABOG registry refresh configured.\n",
         "  Set one with use_abog_refresh(\"<path>\"), or fetch the canonical copy\n",
         "  listed in mufflyaccess::abog_refresh_provenance().", call. = FALSE)
  for (p in cand) {
    ok <- tryCatch({ if (verify) verify_abog_refresh(p); TRUE }, error = function(e) FALSE)
    if (ok) return(p)
  }
  stop("none of the configured paths is the canonical ABOG refresh:\n  ",
       paste(cand, collapse = "\n  "), call. = FALSE)
}

#' Read the ABOG certification registry refresh
#'
#' Verifies the file's hash before reading, so a stale or partial copy cannot
#' enter an analysis unnoticed.
#' @param path Optional explicit path; otherwise resolved as above.
#' @return A data frame of 79,398 registry rows.
#' @export
read_abog_refresh <- function(path = NULL) {
  p <- if (is.null(path)) abog_refresh_path(verify = TRUE) else { verify_abog_refresh(path); path }
  d <- utils::read.csv(p, stringsAsFactors = FALSE)
  need <- c("userid", "name", "startDate", "certStatus", "mocStatus",
            "city", "state", "ID", "ScrapedAt", "refresh_source")
  miss <- setdiff(need, names(d))
  if (length(miss))
    stop("ABOG refresh is missing column(s): ", paste(miss, collapse = ", "),
         "\n  The hash matched, so this is a schema change, not a wrong file.", call. = FALSE)
  d
}

#' Provenance of the ABOG registry SSOT
#' @return A list describing the canonical copies and the expected checksum.
#' @export
abog_refresh_provenance <- function() {
  f <- file.path(.ssot_dir(), "ssot_sources.json")
  src <- if (file.exists(f) && requireNamespace("jsonlite", quietly = TRUE))
    jsonlite::fromJSON(f)$abog_refresh else list()
  resolved <- tryCatch(abog_refresh_path(verify = TRUE), error = function(e) NA_character_)
  c(list(sha256 = .abog_expected_sha(), resolved_path = resolved,
         verified = !is.na(resolved)), src)
}
