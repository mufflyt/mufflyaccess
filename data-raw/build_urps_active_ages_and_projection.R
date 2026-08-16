#!/usr/bin/env Rscript
# =============================================================================
# Build the URPS active-age distribution and canonical projection artifacts
# =============================================================================
# Run from the package root, with a cliff checkout available:
#   CLIFF_ROOT=~/cliff Rscript data-raw/build_urps_active_ages_and_projection.R
#
# WHY THESE EXIST. mufflyaccess already serves URPS counts, lineage, hazards,
# scenarios and the FTE curve. It did NOT serve two facts that every consumer
# needs, so each consumer kept its own copy:
#
#   the active-age distribution   cliff's Shiny app carried it as a 1,306-element
#                                 LITERAL vector, replicated across apps and kept
#                                 in step by a bespoke sync script plus a drift
#                                 guard -- machinery that exists only because
#                                 there was no upstream source.
#
#   the canonical projection      baseline -> 2029 headcount, replacement ratio,
#                                 mean annual exits. These lived only in cliff
#                                 CSVs, so the apps shipped copies. Two of those
#                                 copies were found diverged on 2026-08-16: one
#                                 app was presenting a 1,339-based supply curve
#                                 while the repository had moved to 1,306.
#
# A fact stored twice drifts. These artifacts move both facts to one home.
#
# The package OWNS the definitions; it does not run the projection. cliff
# produces the numbers, this bundles the reviewed result.
# =============================================================================

cliff <- Sys.getenv("CLIFF_ROOT", "~/cliff")
cliff <- path.expand(cliff)
if (!dir.exists(cliff)) stop("CLIFF_ROOT does not exist: ", cliff, call. = FALSE)

out_dir <- file.path("inst", "extdata")
stopifnot(dir.exists(out_dir))

msg <- function(...) cat(" ", ..., "\n")

# ---------------------------------------------------------------------------
# 1. Active-age distribution
#
# Source: cliff's v3.0.0 cohort-age cube, already faceted by pathway and
# geography. Only the two BASE pathways are stored; ABOG_PLUS_ABU is summed by
# the accessor rather than stored, so a stored total can never disagree with the
# parts it is made of.
# ---------------------------------------------------------------------------
ages_src <- file.path(cliff, "scripts", "urps_scenario_cube",
                      "urps_cohort_ages_pathway_geo_v3.0.0.csv")
if (!file.exists(ages_src)) stop("missing cohort-age source: ", ages_src, call. = FALSE)

a <- utils::read.csv(ages_src, stringsAsFactors = FALSE)
stopifnot(all(c("age", "pathway", "geography", "n_active_2023") %in% names(a)))

# cliff writes ABOG / ABU; the count contract's vocabulary is
# ABOG / ABU_NET_NEW / ABOG_PLUS_ABU. Translate at the boundary.
a$board_pathway <- ifelse(a$pathway == "ABU", "ABU_NET_NEW", a$pathway)
ages <- data.frame(
  age           = as.integer(a$age),
  board_pathway = a$board_pathway,
  geography     = a$geography,
  n_active      = as.integer(a$n_active_2023),
  stringsAsFactors = FALSE
)
ages <- ages[order(ages$geography, ages$board_pathway, ages$age), ]

nat <- sum(ages$n_active[ages$geography == "national"])
con <- sum(ages$n_active[ages$geography == "conus"])
msg("active ages: national", nat, "| conus", con, "| rows", nrow(ages))
if (nat != 1306L || con != 1303L)
  stop("age totals do not match the v3.0.0 contract (expected 1306 / 1303).", call. = FALSE)

utils::write.csv(ages, file.path(out_dir, "urps_active_ages.csv"),
                 row.names = FALSE, quote = FALSE)
msg("wrote inst/extdata/urps_active_ages.csv")

# ---------------------------------------------------------------------------
# 2. Canonical projection
#
# Sources: cliff's SSOT (workforce_projections_consolidated.csv, written by
# scripts/rebuild_ssot_revised.R) plus the graduation->active transition table
# for the entry-ramped variant.
# ---------------------------------------------------------------------------
ssot_src <- file.path(cliff, "data", "workforce_projections_consolidated.csv")
tran_src <- file.path(cliff, "data", "graduation_active_transition_projection.csv")
for (f in c(ssot_src, tran_src)) if (!file.exists(f)) stop("missing: ", f, call. = FALSE)

s <- utils::read.csv(ssot_src, stringsAsFactors = FALSE)
t <- utils::read.csv(tran_src, stringsAsFactors = FALSE)

su <- s[toupper(s$subspecialty_abbrev) == "URPS", , drop = FALSE]
tu <- t[toupper(t$subspecialty_abbrev) == "URPS", , drop = FALSE]
stopifnot(nrow(su) == 1L, nrow(tu) == 1L)

if (as.integer(su$baseline_2025) != nat)
  stop(sprintf("SSOT baseline (%s) disagrees with the age distribution total (%d).",
               su$baseline_2025, nat), call. = FALSE)

proj <- data.frame(
  scenario_id            = "baseline",
  specialty              = "URPS",
  certification_pathway  = "ABOG_PLUS_ABU",
  geography_type         = "national",
  geography_id           = "US",
  baseline_year          = 2025L,
  baseline_headcount     = as.integer(su$baseline_2025),
  horizon_year           = 2029L,
  projected_headcount    = as.numeric(su$projected_2029),
  projected_headcount_ramped = as.numeric(tu$projected_2029_ramped),
  sd                     = as.numeric(su$sd_2029),
  lower_95               = as.numeric(su$ci95_lower),
  upper_95               = as.numeric(su$ci95_upper),
  annual_entrants        = as.numeric(su$annual_entrants),
  mean_annual_exits      = as.numeric(su$avg_annual_retirements),
  replacement_ratio      = as.numeric(su$replacement_ratio),
  stringsAsFactors       = FALSE
)

# The ratio must be the entrants/exits it claims to be, to the precision stored.
if (abs(proj$replacement_ratio - proj$annual_entrants / proj$mean_annual_exits) > 1e-6)
  stop("replacement_ratio is not annual_entrants / mean_annual_exits.", call. = FALSE)

msg("projection:", proj$baseline_headcount, "->", round(proj$projected_headcount, 1),
    "| ramped", proj$projected_headcount_ramped,
    "| ratio", round(proj$replacement_ratio, 3))

utils::write.csv(proj, file.path(out_dir, "urps_projection_canonical.csv"),
                 row.names = FALSE, quote = FALSE)
msg("wrote inst/extdata/urps_projection_canonical.csv")
