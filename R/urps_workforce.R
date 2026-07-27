#' Active URPS workforce headcount, 2025 baseline (with and without the urology pathway)
#'
#' @description Frozen active-workforce headcounts for urogynecology and reconstructive
#'   pelvic surgery (URPS), so downstream code gets the SAME number every time instead
#'   of re-deriving it from a pipeline run. Two cohort definitions:
#'
#'   * `URPS_COUNT_ABOG_ONLY_2025` -- WITHOUT the urology pathway: physicians certified
#'     through the American Board of Obstetrics and Gynecology (OB/GYN) pathway only.
#'   * `URPS_COUNT_ABOG_PLUS_ABU_2025` -- WITH the urology pathway: the both-pathway
#'     cohort, adding American Board of Urology (ABU) net-new active urogynecologists.
#'
#'   They reconcile exactly: 1,031 ABOG + 264 ABU net-new = 1,295 both-pathway.
#'
#'   The "2025" is the workforce-model baseline year; the underlying rosters are the
#'   2026-07 cliff extracts. These are ACTIVE-workforce headcounts, NOT the year-forward
#'   projections (e.g. the 2026 projected both-pathway supply is a distinct quantity).
#' @source cliff `data/abu_pathway_sensitivity.csv` (scenarios A/B), from the
#'   `abu_pathway_sensitivity.R` workforce analysis; ABOG rosters
#'   `abog_all_urps_2026-07-22.csv`, ABU rosters `abu_all_urps_2026-07-22.csv`.
#' @family URPS workforce
#' @seealso The reproducible by-year / by-subspecialty pipeline in
#'   `analysis/urps_counts/`, which lands on the same ABOG active figure (1031).
#' @examples
#' URPS_COUNT_ABOG_ONLY_2025                     # 1031  (without urology)
#' URPS_COUNT_ABOG_PLUS_ABU_2025                 # 1295  (with urology)
#' # reconciliation and provenance travel with the values as attributes:
#' attr(URPS_COUNT_ABOG_PLUS_ABU_2025, "note")   # "= ... + 264 ABU net-new active"
#' URPS_COUNT_ABOG_PLUS_ABU_2025 - URPS_COUNT_ABOG_ONLY_2025  # 264
#' @name urps_workforce_2025
NULL

#' @rdname urps_workforce_2025
#' @export
URPS_COUNT_ABOG_ONLY_2025 <- structure(
  1031L,
  year   = 2025L,
  cohort = "active URPS, ABOG (OB/GYN) pathway only -- WITHOUT urology",
  source = "cliff abu_pathway_sensitivity.csv scenario A (rosters 2026-07)"
)

#' @rdname urps_workforce_2025
#' @export
URPS_COUNT_ABOG_PLUS_ABU_2025 <- structure(
  1295L,
  year   = 2025L,
  cohort = "active URPS, both-pathway (ABOG + ABU net-new) -- WITH urology",
  source = "cliff abu_pathway_sensitivity.csv scenario B (rosters 2026-07)",
  note   = "= URPS_COUNT_ABOG_ONLY_2025 (1031) + 264 ABU net-new active"
)

# fail loudly if the frozen values are ever edited into an inconsistent state
stopifnot(
  "[urps_workforce] ABOG-only must be a single positive integer" =
    is.integer(URPS_COUNT_ABOG_ONLY_2025) && length(URPS_COUNT_ABOG_ONLY_2025) == 1L &&
    URPS_COUNT_ABOG_ONLY_2025 > 0L,
  "[urps_workforce] both-pathway must exceed ABOG-only (ABU adds physicians)" =
    URPS_COUNT_ABOG_PLUS_ABU_2025 > URPS_COUNT_ABOG_ONLY_2025,
  "[urps_workforce] both-pathway minus ABOG-only must equal the 264 ABU net-new" =
    (URPS_COUNT_ABOG_PLUS_ABU_2025 - URPS_COUNT_ABOG_ONLY_2025) == 264L
)
