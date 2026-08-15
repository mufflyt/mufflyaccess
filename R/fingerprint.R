# Canonical SHA-256 fingerprinting (SSOT) ------------------------------------
#
# The canonical hash/digest functions behind the provenance contract, promoted
# from simulation (R/core-repro_provenance.R). The real cross-repo drift risk is
# semantic: WHAT gets hashed and HOW, not JSON serialization. Consumers that
# hand-roll digest(file = ...) should call these so every repo's provenance
# hashes the same way. (The heavier write/read artifact contract that consumes
# these -- atomic write, sidecar, read-time content-SHA verify -- is intentionally
# NOT promoted yet; it drags reproducibility-mode + IO policy and is a separate
# slice.)

#' SHA-256 fingerprint of an in-memory R object
#'
#' @param x Any R object.
#' @return 64-character hex digest.
#' @examples
#' fingerprint_object(list(a = 1, b = "x"))
#' @export
fingerprint_object <- function(x) {
  digest::digest(x, algo = "sha256")
}

#' SHA-256 fingerprint of the producing source file(s)
#'
#' Lets an artifact record which code produced it (the `code_fingerprint`
#' provenance field), so a cache is rejected when the generating logic changes
#' even if the inputs did not. Order-independent (paths are sorted) and content-
#' based.
#'
#' @param paths Character vector of file paths.
#' @return 64-character hex digest over the (sorted) per-file digests, or
#'   `NA_character_` if no path exists.
#' @examples
#' \dontrun{
#' fingerprint_files(c("R/foo.R", "R/bar.R"))
#' }
#' @export
fingerprint_files <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) == 0) {
    return(NA_character_)
  }
  digests <- vapply(
    sort(existing),
    function(p) digest::digest(file = p, algo = "sha256"),
    character(1)
  )
  digest::digest(paste(digests, collapse = ""), algo = "sha256")
}
