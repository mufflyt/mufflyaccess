# ==============================================================================
# The URPS active-age distribution.
#
# WHY THIS IS HERE. Consumers need the age distribution of the active cohort to
# run any age-structured projection, and mufflyaccess did not serve it. So every
# consumer kept a copy: cliff's Shiny scenarios app carried it as a
# 1,306-element LITERAL vector, replicated into a second app, kept in step by a
# bespoke sync script and a drift guard -- machinery whose only purpose was to
# compensate for the absence of an upstream source.
#
# A fact stored twice drifts. Two copies of URPS artifacts were found diverged on
# 2026-08-16, one of them presenting a 1,339-based supply curve months after the
# repository had moved to 1,306.
#
# Only the two BASE pathways are stored. ABOG_PLUS_ABU is summed on read rather
# than stored, so the total can never disagree with the parts it is made of.
# ==============================================================================

.urps_read_active_ages <- function() {
  d <- utils::read.csv(.urps_path("urps_active_ages.csv"), stringsAsFactors = FALSE)
  d$age <- as.integer(d$age)
  d$n_active <- as.integer(d$n_active)
  d
}

#' The URPS active-age distribution
#'
#' @description Age distribution of the active urogynecology cohort, served from
#'   the bundled artifact so no consumer has to carry its own copy. This is the
#'   input an age-structured projection starts from; pair it with
#'   [urps_retirement_hazard()] to run one.
#' @details The stored artifact holds the two base pathways (`ABOG`,
#'   `ABU_NET_NEW`) for each geography. `ABOG_PLUS_ABU` is summed on read rather
#'   than stored, so a combined total cannot disagree with its parts.
#'
#'   The result is checked against [urps_count()] on every call: the ages must
#'   total the published active count for the same pathway and geography. A
#'   distribution that does not add up to the count the package serves is a
#'   contradiction, and it fails loud rather than returning a plausible number.
#' @param pathway Board pathway: `"ABOG_PLUS_ABU"` (default), `"ABOG"`, or
#'   `"ABU_NET_NEW"`. Case-insensitive.
#' @param geography `"national"` (default) or `"conus"`.
#' @param as `"counts"` (default) for one row per age, or `"vector"` for the
#'   distribution expanded to one element per provider -- the form a
#'   microsimulation consumes directly.
#' @return With `as = "counts"`, a `data.frame` with columns `age` (integer) and
#'   `n_active` (integer), ordered by age. With `as = "vector"`, an integer
#'   vector of length equal to the active count.
#' @seealso [urps_count()] for the totals these must reconcile to,
#'   [urps_projection()] for the canonical projection built from them,
#'   [urps_retirement_hazard()], [urps_lineage()].
#' @family URPS SSOT
#' @examples
#' head(urps_active_ages())
#' length(urps_active_ages(as = "vector"))     # == urps_count(2023, "board_certified_active",
#' #                                                "national", include_urology = TRUE)
#' head(urps_active_ages("ABOG", "conus"))
#' @export
urps_active_ages <- function(pathway = "ABOG_PLUS_ABU",
                             geography = "national",
                             as = c("counts", "vector")) {
  as <- match.arg(as)
  # Reuse .urps_norm_choice() rather than a second normalizer: it lowercases,
  # so compare against the lowercased vocabulary and restore the contract's
  # uppercase form. One validator, and nothing new for lintr to resolve
  # across files.
  pathway <- toupper(.urps_norm_choice(pathway, "pathway", tolower(.urps_pathways)))
  geography <- .urps_norm_choice(geography, "geography", .urps_geographies)

  d <- .urps_read_active_ages()
  keep <- if (identical(pathway, "ABOG_PLUS_ABU")) {
    d$geography == geography
  } else {
    d$geography == geography & d$board_pathway == pathway
  }
  d <- d[keep, , drop = FALSE]
  if (!nrow(d)) {
    stop(sprintf("[urps_active_ages] no age distribution for %s / %s.",
                 pathway, geography), call. = FALSE)
  }

  agg <- stats::aggregate(list(n_active = d$n_active), by = list(age = d$age), FUN = sum)
  agg <- agg[order(agg$age), , drop = FALSE]
  rownames(agg) <- NULL
  agg$age <- as.integer(agg$age)
  agg$n_active <- as.integer(agg$n_active)

  # The distribution must total the count the package publishes for the same
  # slice. If these disagree, one of the two artifacts is wrong and a caller must
  # not be handed either.
  expected <- urps_count(
    year = 2023L, measure = "board_certified_active", geography = geography,
    include_urology = identical(pathway, "ABOG_PLUS_ABU"), incomplete = "na"
  )
  got <- sum(agg$n_active)
  if (identical(pathway, "ABOG_PLUS_ABU") && !is.na(expected) && got != expected) {
    stop(sprintf(paste0(
      "[urps_active_ages] the age distribution totals %d but urps_count() ",
      "publishes %d for %s / %s. The bundled artifacts disagree."),
      got, expected, pathway, geography), call. = FALSE)
  }

  if (identical(as, "counts")) {
    return(agg)
  }
  rep(agg$age, times = agg$n_active)
}
