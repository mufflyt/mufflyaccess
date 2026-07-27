#!/usr/bin/env Rscript
# =============================================================================
# subspecialist_counts.R -- repo-local deriving accessor for ABOG OB/GYN
# subspecialist counts (ACTIVE vs EVER-CERTIFIED), by subspecialty and year.
#
# Reads the committed, provenance-stamped urps_by_year_subspecialty.csv (built by
# count_urps.py from the isochrones cohort) and returns counts. It NEVER hardcodes
# an integer and FAILS LOUDLY if the CSV is missing -- so it can only ever return
# the number that traces to the current committed source (see provenance.json).
#
# MEASURES (per subspecialty x year):
#   active          -- physicians in the workforce that year:
#                      certification_year <= Y AND (retirement_year empty OR > Y)
#   ever_certified  -- cumulative ABOG certifications with cert year <= Y
#   retired         -- detected retirements with retirement year <= Y
#   pct_active      -- 100 * active / ever_certified
# At the final snapshot year, ever_certified == the all-time cohort size
# (e.g. GO 2023: active 1052, ever_certified 1190).
#
# Board caveat: ABOG (OB/GYN) pathway only. For URPS "with urology" (+ ABU),
# see count_urps.py --abu. GO/MFM/REI/MIGS/CFP/PAG are ABOG-only (no split).
# =============================================================================

# Locate the committed CSV: explicit `file`, then options(urps.counts_csv=),
# then next to this script, then common working-dir-relative paths.
.find_counts_csv <- function(file = NULL) {
  if (!is.null(file)) {
    if (!file.exists(file))
      stop("[subspecialist_counts] CSV not found at: ", file, call. = FALSE)
    return(normalizePath(file))
  }
  opt <- getOption("urps.counts_csv")
  cand <- c(opt,
            file.path(.this_script_dir(), "urps_by_year_subspecialty.csv"),
            "analysis/urps_counts/urps_by_year_subspecialty.csv",
            "urps_by_year_subspecialty.csv")
  cand <- cand[!vapply(cand, is.null, logical(1))]
  hit  <- cand[file.exists(cand)]
  if (length(hit) == 0L)
    stop("[subspecialist_counts] could not find urps_by_year_subspecialty.csv. ",
         "Pass file=..., set options(urps.counts_csv=...), or run from the repo root. ",
         "Tried: ", paste(cand, collapse = ", "), call. = FALSE)
  normalizePath(hit[[1]])
}

# Best-effort directory of this script (works when sourced or Rscript-run).
.this_script_dir <- function() {
  ofile <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (!is.null(ofile)) return(dirname(normalizePath(ofile)))
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(dirname(normalizePath(sub("^--file=", "", a[[1]]))))
  getwd()
}

#' Active vs ever-certified ABOG subspecialist counts.
#'
#' @param subspecialty Optional filter: an abbreviation ("GO", "URPS", "MFM",
#'   "REI", "MIGS", "CFP", "PAG") or a full subspecialty name (case-insensitive).
#'   NULL returns all subspecialties.
#' @param year Optional integer year(s) in 2013:2023. NULL returns all years.
#' @param file Optional path to urps_by_year_subspecialty.csv (auto-located if NULL).
#' @return data.frame with columns year, subspecialty, abbrev, n_active,
#'   n_ever_certified, n_retired, pct_active -- sorted by subspecialty then year.
subspecialist_counts <- function(subspecialty = NULL, year = NULL, file = NULL) {
  path <- .find_counts_csv(file)
  df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  need <- c("year","subspecialty","abbrev","n_active","n_ever_certified_by_year","n_retired_by_year")
  miss <- setdiff(need, names(df))
  if (length(miss))
    stop("[subspecialist_counts] CSV missing columns: ", paste(miss, collapse = ", "),
         " (", path, ")", call. = FALSE)

  out <- data.frame(
    year             = as.integer(df$year),
    subspecialty     = df$subspecialty,
    abbrev           = df$abbrev,
    n_active         = as.integer(df$n_active),
    n_ever_certified = as.integer(df$n_ever_certified_by_year),
    n_retired        = as.integer(df$n_retired_by_year),
    stringsAsFactors = FALSE)
  out$pct_active <- round(100 * out$n_active / out$n_ever_certified, 1)

  if (!is.null(subspecialty)) {
    key <- toupper(trimws(subspecialty))
    keep <- toupper(out$abbrev) %in% key | toupper(out$subspecialty) %in% key
    if (!any(keep))
      stop("[subspecialist_counts] unknown subspecialty '", subspecialty,
           "'. Known abbrevs: ", paste(sort(unique(out$abbrev)), collapse = ", "),
           call. = FALSE)
    out <- out[keep, , drop = FALSE]
  }
  if (!is.null(year)) {
    yr <- as.integer(year)
    keep <- out$year %in% yr
    if (!any(keep))
      stop("[subspecialist_counts] no rows for year(s): ", paste(yr, collapse = ", "),
           ". Available: ", paste(range(out$year), collapse = "-"), call. = FALSE)
    out <- out[keep, , drop = FALSE]
  }
  out <- out[order(out$subspecialty, out$year), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Scalar: number ACTIVE for one subspecialty in one year.
#' @inheritParams subspecialist_counts
#' @return integer scalar.
n_active <- function(subspecialty, year, file = NULL) {
  r <- subspecialist_counts(subspecialty, year, file)
  if (nrow(r) != 1L)
    stop("[n_active] expected one subspecialty x one year; got ", nrow(r), " rows.", call. = FALSE)
  r$n_active
}

#' Scalar: number EVER CERTIFIED (cumulative through year) for one subspecialty.
#' @inheritParams subspecialist_counts
#' @return integer scalar.
n_ever_certified <- function(subspecialty, year, file = NULL) {
  r <- subspecialist_counts(subspecialty, year, file)
  if (nrow(r) != 1L)
    stop("[n_ever_certified] expected one subspecialty x one year; got ", nrow(r), " rows.", call. = FALSE)
  r$n_ever_certified
}

# CLI: Rscript subspecialist_counts.R [SUBSPEC] [YEAR]
if (sys.nframe() == 0L) {
  a <- commandArgs(TRUE)
  sub <- if (length(a) >= 1) a[[1]] else NULL
  yr  <- if (length(a) >= 2) as.integer(a[[2]]) else NULL
  print(subspecialist_counts(sub, yr))
}
