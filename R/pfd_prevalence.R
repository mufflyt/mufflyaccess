#' Wu 2014 age-specific symptomatic pelvic-floor-disorder (PFD) prevalence, women 65+
#'
#' @description The demand denominator behind the relative-availability /
#'   need-based-adequacy / condition-demand access numbers. `any_PFD` is the
#'   primary denominator; `UI`/`FI`/`POP` are the condition-specific variants.
#'
#'   SCOPE: this is the 65+ ACCESS denominator (Wu 2014). It is DISTINCT from the
#'   workforce-cliff supply/demand line, which uses a full-age-curve Nygaard-2008
#'   table for a population projection -- a different cohort/source that is
#'   intentionally NOT this object and stays in the cliff repo. Do not conflate.
#' @format `data.frame` (condition x p_65_79 / p_80plus), proportions.
#' @source Primary: Wu JM, Vaughan CP, Goode PS, et al. "Prevalence and trends of
#'   symptomatic pelvic floor disorders in U.S. women." Obstet Gynecol
#'   2014;123(1):141-148, Table 1. PMID 24463674; doi:10.1097/AOG.0000000000000057
#'   (estimates derived from NHANES 2005-2010). Promoted from
#'   isochrones/R/pfd_prevalence.R.
#' @family pfd-prevalence
#' @seealso [pfd_prevalence()] and [pfd_prevalence_acs_bands()], the accessors.
#' @examples
#' WU2014_PFD_PREVALENCE
#' attr(WU2014_PFD_PREVALENCE, "source")
#' @export
WU2014_PFD_PREVALENCE <- local({
  d <- data.frame(
    condition = c("any_PFD", "UI", "FI", "POP"),
    p_65_79 = c(0.368, 0.272, 0.154, 0.047), # Wu 2014 Table 1, ages 60-79
    p_80plus = c(0.497, 0.382, 0.210, 0.040), # Wu 2014 Table 1, ages >=80
    stringsAsFactors = FALSE
  )
  attr(d, "source") <- "Wu JM et al. Obstet Gynecol 2014;123(1):141-148, Table 1 (PMID 24463674; doi:10.1097/AOG.0000000000000057; NHANES 2005-2010)"
  attr(d, "brackets") <- c("60-79 (applied to 65-79 ACS bands)", ">=80")
  attr(d, "units") <- "proportion of women in the age bracket with the (symptomatic) disorder"
  d
})

.PFD_BANDS_65_79 <- c("a65_66E", "a67_69E", "a70_74E", "a75_79E")
.PFD_BANDS_80P <- c("a80_84E", "a85pE")

stopifnot(
  "[pfd] condition must be unique" = !anyDuplicated(WU2014_PFD_PREVALENCE$condition),
  "[pfd] any_PFD row required" = "any_PFD" %in% WU2014_PFD_PREVALENCE$condition,
  "[pfd] prevalences must be in (0,1]" =
    all(is.finite(c(WU2014_PFD_PREVALENCE$p_65_79, WU2014_PFD_PREVALENCE$p_80plus))) &&
      all(c(WU2014_PFD_PREVALENCE$p_65_79, WU2014_PFD_PREVALENCE$p_80plus) > 0) &&
      all(c(WU2014_PFD_PREVALENCE$p_65_79, WU2014_PFD_PREVALENCE$p_80plus) <= 1)
)

#' Two-bracket Wu-2014 PFD prevalence for one condition
#' @param condition one of `WU2014_PFD_PREVALENCE$condition` (default "any_PFD").
#' @return named numeric `c(`65_79`=, `80plus`=)`.
#' @family pfd-prevalence
#' @seealso [WU2014_PFD_PREVALENCE] (the underlying table),
#'   [pfd_prevalence_acs_bands()] (the same rates spread over ACS age-band columns).
#' @examples
#' pfd_prevalence() # any_PFD: c(`65_79` = 0.368, `80plus` = 0.497)
#' pfd_prevalence("UI") # urinary incontinence: c(`65_79` = 0.272, `80plus` = 0.382)
#' \dontrun{
#' pfd_prevalence("nope") # errors: unknown condition
#' }
#' @export
pfd_prevalence <- function(condition = "any_PFD") {
  r <- WU2014_PFD_PREVALENCE[WU2014_PFD_PREVALENCE$condition == condition, , drop = FALSE]
  if (nrow(r) != 1L) {
    stop("[pfd_prevalence] unknown condition '", condition, "' (have: ",
      paste(WU2014_PFD_PREVALENCE$condition, collapse = ", "), ")",
      call. = FALSE
    )
  }
  c(`65_79` = r$p_65_79, `80plus` = r$p_80plus)
}

#' Wu-2014 PFD prevalence as a named vector over the ACS 65+ age-band columns
#' @param condition one of `WU2014_PFD_PREVALENCE$condition` (default "any_PFD").
#' @return named numeric over c(a65_66E, a67_69E, a70_74E, a75_79E, a80_84E, a85pE).
#' @family pfd-prevalence
#' @seealso [pfd_prevalence()] (the two-bracket form these bands expand).
#' @examples
#' b <- pfd_prevalence_acs_bands() # any_PFD spread across the 6 ACS 65+ bands
#' b[["a65_66E"]] # 0.368  (65-79 bracket rate)
#' b[["a85pE"]] # 0.497  (>=80 bracket rate)
#' # the four 65-79 bands all carry the 65-79 rate; the two 80+ bands the 80+ rate:
#' unname(b) # c(0.368, 0.368, 0.368, 0.368, 0.497, 0.497)
#' @export
pfd_prevalence_acs_bands <- function(condition = "any_PFD") {
  v <- pfd_prevalence(condition)
  stats::setNames(
    c(
      rep(v[["65_79"]], length(.PFD_BANDS_65_79)),
      rep(v[["80plus"]], length(.PFD_BANDS_80P))
    ),
    c(.PFD_BANDS_65_79, .PFD_BANDS_80P)
  )
}
