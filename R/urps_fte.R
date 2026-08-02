# ==============================================================================
# URPS clinical-FTE model (Phase 3).
#
# The projection contract (urps_projection.R, Phase 2) reserves a
# `supply_clinical_fte` column and leaves it NA until this model exists. This file
# is that model: the canonical headcount -> clinical-FTE capacity weighting that
# cliff applies when it emits a projection table, and that any consumer uses to
# interpret / recompute the FTE column. mufflyaccess OWNS the definition (one age
# curve + one pathway clinical-time constant); it does not run the projection.
#
# supply_clinical_fte is a normalized CAPACITY INDEX (effective providers), not
# absolute hours: weight(age, pathway) = age_productivity(age) * pathway_clinical_time,
# and a caller anchors it with urps_fte_scale() so a chosen reference cohort's
# effective FTE equals its headcount, which makes effective FTE additive across the
# pathway / geography slices of the projection cube.
#
# The late-career FTE lever (factor + onset age) is NOT redefined here -- it lives
# in the scenario registry (urps_scenarios(): late_career_fte_factor /
# late_career_fte_onset_age). urps_fte_weight() just applies whatever the caller
# passes from that registry, so the two cannot drift.
# ==============================================================================

#' Pathway clinical-time fractions for the URPS clinical-FTE weighting
#'
#' @description Fraction of clinical time an active urogynecologist spends in
#'   urogynecology, by board pathway. ABOG-pathway physicians are treated as full
#'   clinical time in urogynecology; ABU (urology) pathway physicians spend part of
#'   their clinical time in general urology. This is the single canonical constant
#'   consumers weight headcount by; it must not be redefined per repository.
#' @format Named numeric vector: `ABOG = 1.00`, `ABU = 0.70`.
#' @seealso [urps_fte_weight()], [urps_scenarios()]
#' @family URPS FTE
#' @examples
#' URPS_FTE_PATHWAY_CLINICAL_TIME[["ABU"]]
#' @export
URPS_FTE_PATHWAY_CLINICAL_TIME <- c(ABOG = 1.00, ABU = 0.70)

#' The canonical URPS age-productivity curve
#'
#' @description Relative-to-peak clinical productivity by age (the age component of
#'   the clinical-FTE weight), served from the bundled dataset so every consumer
#'   uses one curve.
#' @return A `data.frame` with columns `age` (integer) and `rel_to_peak` (numeric).
#' @seealso [urps_fte_weight()]
#' @family URPS FTE
#' @examples
#' head(urps_fte_age_curve())
#' @export
urps_fte_age_curve <- function() {
  d <- utils::read.csv(.urps_path("urps_fte_age_curve.csv"), stringsAsFactors = FALSE)
  data.frame(age = as.integer(d$age), rel_to_peak = as.numeric(d$rel_to_peak))
}

#' Per-provider URPS clinical-FTE weight
#'
#' @description The canonical headcount->FTE weight for one or more providers:
#'   age productivity x pathway clinical time x an optional late-career factor.
#'   Multiply by a headcount and a normalization scale (see [urps_fte_scale()]) for
#'   a clinical-FTE capacity index.
#' @param age Integer/numeric age(s), clamped to the curve's support.
#' @param pathway `"ABOG"` / `"ABU"` (recycled against `age`); any other value is
#'   treated as full clinical time (e.g. a pre-combined cohort). `"ABOG_PLUS_ABU"`
#'   is NOT a per-provider pathway -- weight ABOG and ABU providers separately and
#'   sum, so the combined weight reflects the true pathway mix.
#' @param late_from_age If non-`NULL`, ages at/above this get `late_factor`
#'   (pass `urps_scenario(id)$late_career_fte_onset_age`).
#' @param late_factor Late-career clinical-FTE multiplier
#'   (pass `urps_scenario(id)$late_career_fte_factor`; default 1 = no reduction).
#' @return Numeric weight(s), same length as `age`.
#' @seealso [urps_effective_fte()], [urps_fte_scale()], [urps_scenarios()]
#' @family URPS FTE
#' @examples
#' urps_fte_weight(c(45, 62), c("ABOG", "ABU"), late_from_age = 60, late_factor = 0.75)
#' @export
urps_fte_weight <- function(age, pathway = "ABOG", late_from_age = NULL, late_factor = 1) {
  curve <- urps_fte_age_curve()
  a   <- pmin(pmax(age, min(curve$age)), max(curve$age))
  rel <- curve$rel_to_peak[match(a, curve$age)]
  ct  <- unname(URPS_FTE_PATHWAY_CLINICAL_TIME[pathway]); ct[is.na(ct)] <- 1.0
  late <- if (!is.null(late_from_age)) ifelse(age >= late_from_age, late_factor, 1) else 1
  rel * ct * late
}

#' Effective clinical-FTE of a headcount cohort
#'
#' @description Clinical-FTE capacity index for a cohort given as counts by age and
#'   pathway: `scale * sum(n * urps_fte_weight(age, pathway, ...))`. Pass `scale`
#'   from [urps_fte_scale()] so a reference cohort's effective FTE equals its
#'   headcount, making effective FTE additive across pathway / geography slices.
#' @param counts A `data.frame` with columns `age`, `pathway`, `n`.
#' @param scale Normalization scale (default 1 = raw weighted sum).
#' @param late_from_age,late_factor Passed to [urps_fte_weight()].
#' @return A length-1 numeric.
#' @seealso [urps_fte_scale()], [urps_fte_weight()]
#' @family URPS FTE
#' @examples
#' cs <- data.frame(age = c(45, 62, 45, 62), pathway = c("ABOG","ABOG","ABU","ABU"), n = c(10,5,4,2))
#' urps_effective_fte(cs, scale = urps_fte_scale(cs))
#' @export
urps_effective_fte <- function(counts, scale = 1, late_from_age = NULL, late_factor = 1) {
  stopifnot(all(c("age", "pathway", "n") %in% names(counts)))
  w <- urps_fte_weight(counts$age, counts$pathway, late_from_age, late_factor)
  as.numeric(scale) * sum(counts$n * w)
}

#' Normalization scale anchoring a reference cohort's effective FTE to a target
#'
#' @param reference_counts A `data.frame(age, pathway, n)` (e.g. the baseline-year
#'   combined national active cohort).
#' @param target_headcount The headcount the reference cohort's effective FTE should
#'   equal (default `sum(reference_counts$n)`, i.e. FTE(reference) == headcount).
#' @return A length-1 numeric scale for [urps_effective_fte()].
#' @seealso [urps_effective_fte()]
#' @family URPS FTE
#' @examples
#' cs <- data.frame(age = c(45, 62), pathway = c("ABOG","ABU"), n = c(10, 4))
#' urps_fte_scale(cs)
#' @export
urps_fte_scale <- function(reference_counts, target_headcount = sum(reference_counts$n)) {
  raw <- urps_effective_fte(reference_counts, scale = 1)
  if (!is.finite(raw) || raw <= 0)
    stop("[urps_fte_scale] reference cohort has non-positive weighted FTE.", call. = FALSE)
  as.numeric(target_headcount) / raw
}
