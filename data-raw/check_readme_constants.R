#!/usr/bin/env Rscript
# =============================================================================
# Verify that README.md still describes the package it ships with
# =============================================================================
# Run from the package root:  Rscript data-raw/check_readme_constants.R
# Exits 1 on any mismatch, so it can run in CI.
#
# WHY THIS EXISTS. README.md documents constant VALUES in prose -- "60 min",
# "164,690,617", "49 two-digit FIPS codes", "1.645". That is the right thing for
# a reader and the wrong thing to leave unchecked: this is the single-source-of-
# truth package, and a README that disagrees with the constants it advertises
# undermines the one guarantee it makes. The export count had already drifted
# (README said 106, the package exported 110) before this check was written.
#
# It compares documentation against the INSTALLED package, not the source, so it
# also catches a README updated for changes that were never installed.
# =============================================================================
suppressPackageStartupMessages(library(mufflyaccess))

readme <- paste(readLines("README.md", warn = FALSE), collapse = "\n")
fails <- 0L

ok <- function(label, claimed, actual) {
  hit <- identical(as.character(claimed), as.character(actual))
  cat(sprintf(
    "  %-4s %-30s README=%-16s package=%s\n",
    if (hit) "PASS" else "FAIL", label, claimed, actual
  ))
  if (!hit) fails <<- fails + 1L
}

# Does the README literally contain this string? Catches values quoted inline
# rather than in a table cell we could parse.
states <- function(pattern, label) {
  hit <- grepl(pattern, readme, fixed = TRUE)
  cat(sprintf("  %-4s %-30s %s\n", if (hit) "PASS" else "FAIL", label, pattern))
  if (!hit) fails <<- fails + 1L
}

cat("--- exported-object count ---\n")
n_exports <- length(getNamespaceExports("mufflyaccess"))
claimed <- suppressWarnings(as.integer(
  sub(
    ".*All ([0-9]+) exported objects.*", "\\1",
    regmatches(readme, regexpr("All [0-9]+ exported objects", readme))
  )
))
ok("exported objects", if (length(claimed)) claimed else "absent", n_exports)

cat("\n--- access bands and thresholds ---\n")
ok("PRIMARY_ACCESS_BAND_MIN", 60, PRIMARY_ACCESS_BAND_MIN)
ok("PRIMARY_ACCESS_BAND_SEC", 3600, PRIMARY_ACCESS_BAND_SEC)
ok("CANONICAL_BANDS", "30, 60, 120, 180", paste(CANONICAL_BANDS, collapse = ", "))
ok("TRACT_REACHED_COVERAGE_PCT", 50, TRACT_REACHED_COVERAGE_PCT)
ok("DENOMINATOR_CATEGORY", "total_female", DENOMINATOR_CATEGORY)

cat("\n--- census denominators ---\n")
ok("ACS2020_CONUS_FEMALE_POP", 164690617, as.numeric(ACS2020_CONUS_FEMALE_POP))
states("164,690,617", "population quoted in README")
ok("TOTAL_FEMALE_VAR", "B01001_026", TOTAL_FEMALE_VAR)

cat("\n--- geography ---\n")
ok("CONUS_STATE_FIPS length", 49, length(CONUS_STATE_FIPS))
ok("CONUS_STATE_ABBR length", 49, length(CONUS_STATE_ABBR))
ok("NON_CONTIGUOUS_FIPS length", 7, length(NON_CONTIGUOUS_FIPS))
# The README's central claim about this pair: they cannot drift because one is
# derived from the other. Assert the relationship, not just the lengths.
ok(
  "ABBR derived from FIPS", TRUE,
  length(CONUS_STATE_ABBR) == length(CONUS_STATE_FIPS)
)
ok("DC in CONUS set", TRUE, "DC" %in% CONUS_STATE_ABBR)
ok("AK/HI excluded", TRUE, !any(c("AK", "HI") %in% CONUS_STATE_ABBR))

cat("\n--- margins of error ---\n")
ok("ACS_MOE_Z90", 1.645, ACS_MOE_Z90)
ok("CI_Z95", 1.96, CI_Z95)
ok(
  "MOE90_TO_CI95_FACTOR derived", round(1.96 / 1.645, 4),
  round(MOE90_TO_CI95_FACTOR, 4)
)

cat("\n--- rurality ---\n")
ok("RUCA_NONMETRO_MIN", 4, RUCA_NONMETRO_MIN)
ok("rurality_from_ruca(3)", "Metropolitan", rurality_from_ruca(3L))
ok("rurality_from_ruca(4)", "Rural", rurality_from_ruca(4L))

cat(sprintf("\n%s\n", strrep("=", 62)))
if (fails) {
  cat(sprintf("README disagrees with the package in %d place(s).\n", fails))
  quit(status = 1)
}
cat("README matches the installed package.\n")
