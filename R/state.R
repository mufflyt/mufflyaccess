#' Standardize US state values to canonical names or 2-letter codes (SSOT)
#'
#' The single canonical state-name normalizer for the OB/GYN subspecialty
#' projects. Promoted from isochrones (`R/utils_standardized.R`) so consumers stop
#' re-rolling `setNames(state.abb, state.name)` lookups. Handles the 50 states, DC,
#' and the five territories (PR, GU, VI, AS, MP) in either direction.
#'
#' The output is byte-identical to the isochrones original; only two isochrones-
#' specific SIDE EFFECTS were dropped (an unconditional `[INFO]` print and an
#' audible `beep`), which have no place in a shared library and do not affect the
#' returned value.
#'
#' @param x Character vector of raw state values (full names, codes, or
#'   underscored names, any case).
#' @param output `"name"` (default) for the full name, or `"abbr"` for the
#'   2-letter USPS code.
#' @return Character vector: canonical name or code; unmapped values fall back to
#'   title case (for `"name"`) or `NA_character_` (for `"abbr"`).
#' @examples
#' standardize_state_name(c("colorado", "TX", "Puerto Rico"), output = "abbr")
#' standardize_state_name(c("co", "tx"), output = "name")
#' @export
standardize_state_name <- function(x, output = c("name", "abbr")) {
  output <- base::match.arg(output)

  # Build maps, include DC and territories. Use explicit is.null() checks (%||%
  # is not guaranteed in callr subprocesses).
  states_raw <- get0("state.name", envir = asNamespace("datasets"))
  if (is.null(states_raw)) {
    states_raw <- get0("state.name", envir = baseenv())
  }
  abbrs_raw <- get0("state.abb", envir = asNamespace("datasets"))
  if (is.null(abbrs_raw)) {
    abbrs_raw <- get0("state.abb", envir = baseenv())
  }

  if (is.null(states_raw) || is.null(abbrs_raw)) {
    stop("standardize_state_name: state lists not available")
  }

  states <- c(states_raw, "District of Columbia")
  abbrs <- c(abbrs_raw, "DC")

  terr_names <- c(
    "Puerto Rico", "Guam", "U.S. Virgin Islands",
    "American Samoa", "Northern Mariana Islands"
  )
  terr_abbrs <- c("PR", "GU", "VI", "AS", "MP")

  names_all <- c(states, terr_names)
  abbr_all <- c(abbrs, terr_abbrs)

  to_name <- stats::setNames(names_all, abbr_all)
  to_abbr <- stats::setNames(
    abbr_all,
    toupper(names_all)
  )

  clean <- function(s) {
    s <- as.character(s)
    s <- trimws(s)
    s <- gsub("[.]", "", s)
    s
  }

  x2 <- vapply(x, clean, character(1))

  conv <- function(val) {
    if (base::is.na(val) || !base::nzchar(val)) {
      return(NA_character_)
    }
    v_up <- toupper(val)

    if (output == "name") {
      if (v_up %in% names(to_name)) {
        return(to_name[[v_up]])
      }
      # fallback title case
      return(tools::toTitleCase(tolower(val)))
    } else {
      # output abbr
      if (v_up %in% abbr_all) {
        return(v_up)
      }
      title <- tools::toTitleCase(tolower(val))
      title_up <- toupper(title)
      if (title_up %in% names(to_abbr)) {
        return(to_abbr[[title_up]])
      }
      return(NA_character_)
    }
  }

  out_vec <- unname(vapply(x2, conv, character(1)))

  # Explicit Puerto Rico fix if anything slipped
  out_vec <- if (output == "name") {
    unname(ifelse(toupper(x2) == "PR", "Puerto Rico", out_vec))
  } else {
    unname(ifelse(toupper(x2) %in% c("PUERTO RICO", "PR"), "PR", out_vec))
  }

  return(unname(out_vec))
}
