#' Canonicalize NPI identifiers to 10-digit strings (SSOT)
#'
#' The single canonical NPI normalizer for the OB/GYN subspecialty projects.
#' Promoted verbatim from isochrones (`R/join_standards.R`) so `twostep`, `cliff`,
#' `simulation`, `mysterycall`, and `mysterymaps` stop re-rolling weaker copies
#' (`sprintf("%.0f")`, `as.integer()`, `trimws()`), which silently corrupt NPIs
#' via leading-zero loss or 32-bit overflow.
#'
#' Strips whitespace/`-`/`.` separators; rejects scientific notation, embedded
#' letters, non-digit-only values, and values with more than 10 digits; then
#' left-zero-pads to 10 and validates `^[0-9]{10}$`. Rejected and NA/empty inputs
#' return `NA_character_`.
#'
#' @param x Atomic vector of raw NPI values (character or numeric).
#' @param verbose Logical; when `TRUE` (default) emit a per-reason summary of
#'   rejected values via [message()].
#' @return Character vector the same length as `x`: a 10-digit NPI or
#'   `NA_character_`.
#' @examples
#' canon_npi(c("1234567893", "12-3456 7890", "abc", NA), verbose = FALSE)
#' @export
canon_npi <- function(x, verbose = TRUE) {
  if (is.null(x)) {
    return(character(0))
  }
  if (!is.atomic(x)) {
    stop("canon_npi: input must be an atomic vector, not a ", class(x)[1], call. = FALSE)
  }

  original <- as.character(x)
  x <- original
  rejection_reasons <- rep(NA_character_, length(x))

  # Handle NA/empty
  empty_mask <- is.na(x) | x == ""
  x[empty_mask] <- NA_character_

  # Reject scientific notation
  is_sci <- grepl("[eE][+-]?[0-9]+", x, perl = TRUE) & !is.na(x)
  rejection_reasons[is_sci] <- "scientific notation"
  x[is_sci] <- NA_character_

  # Strip separators, then reject if letters remain
  cleaned <- stringr::str_replace_all(x, "[\\s\\-\\.]", "")
  has_letters <- grepl("[a-zA-Z]", cleaned) & !is.na(x)
  rejection_reasons[has_letters & is.na(rejection_reasons)] <- "contains letters"
  x[has_letters] <- NA_character_

  # Extract digits
  x <- stringr::str_replace_all(x, "[^0-9]", "")

  # Reject empty after extraction
  no_digits <- x == "" & is.na(rejection_reasons)
  rejection_reasons[no_digits] <- "no digits"
  x[x == ""] <- NA_character_

  # Reject if > 10 digits
  too_long <- !is.na(x) & nchar(x) > 10
  rejection_reasons[too_long & is.na(rejection_reasons)] <- "too many digits"
  x[too_long] <- NA_character_

  # Pad to 10 digits
  x[!is.na(x)] <- stringr::str_pad(x[!is.na(x)], width = 10, side = "left", pad = "0")

  # Validate final format
  bad_format <- !is.na(x) & !stringr::str_detect(x, "^[0-9]{10}$")
  rejection_reasons[bad_format & is.na(rejection_reasons)] <- "invalid format"
  x[bad_format] <- NA_character_

  if (verbose) {
    rejected <- !is.na(rejection_reasons) & !empty_mask
    if (any(rejected)) {
      n_total <- length(x)
      n_rejected <- sum(rejected)
      pct <- n_rejected / n_total * 100
      # One summary line, then per-reason breakdown
      message(sprintf(
        "canon_npi: %d of %d values (%.1f%%) rejected as invalid NPI",
        n_rejected, n_total, pct
      ))
      unique_reasons <- unique(rejection_reasons[rejected])
      for (reason in unique_reasons) {
        vals <- original[rejected & rejection_reasons == reason]
        message(sprintf(
          "  - %s (%d): %s",
          reason, length(vals), paste(utils::head(vals, 3), collapse = ", ")
        ))
      }
    }
  }

  x
}
