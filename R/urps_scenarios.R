# ==============================================================================
# The URPS workforce SCENARIO DICTIONARY (see ARCHITECTURE.md / docs/CHARTER_URPS_SSOT.md).
#
# mufflyaccess owns the *definitions* of the named projection scenarios: a stable,
# versioned enum of scenario_ids, each fixing the LEVER VALUES that define what the
# scenario means. It does NOT own the projection model -- how a lever propagates
# through the workforce recurrence (retirement hazards, entrants, FTE) is cliff's
# engine. This is the single vocabulary that unifies cliff's previously disjoint
# scenario sets, and the enum the cliff->mufflyaccess projection contract keys on.
#
# Lever space (baseline = the neutral origin; every scenario is a point here):
#   entrant_multiplier         scales annual entrants (fellowship output pathway)
#   retirement_shift_years     shifts the retirement-hazard curve (- = earlier exit)
#   late_career_fte_factor     multiplies clinical FTE at/after the onset age
#   late_career_fte_onset_age  age at which the FTE factor begins (NA if none)
#
# A scenario dictionary fixes WHAT a named scenario is (its lever settings), so
# every repo agrees "fellowship_plus_10pct" means entrants x 1.10. It does not fix
# WHAT the levers do -- that model stays in cliff. Lever magnitudes here are the
# registry's declared, versioned policy definitions; revise via a registry bump.
# ==============================================================================

.URPS_SCENARIO_REGISTRY_VERSION <- "1.1.0"

.urps_scenario_families <- c("reference", "retirement", "entry", "fte", "demand", "composite")

# composites are defined as an ordered set of single-lever component scenarios;
# their lever values are RECONSTRUCTED from the components at load and cross-checked
# against the table below, so the registry cannot drift internally.
.urps_scenario_components <- list(
  combined_pessimistic = c("retire_2yr_earlier", "fellowship_constrained", "lower_late_career_fte"),
  combined_investment  = c("retire_2yr_later", "fellowship_plus_10pct")
)

.urps_scenarios_df <- function() {
  data.frame(
    scenario_id = c(
      "baseline", "retire_2yr_earlier", "retire_5yr_earlier", "retire_2yr_later",
      "fellowship_plus_10pct", "fellowship_constrained", "lower_late_career_fte",
      "demand_insurance_expansion", "demand_obesity_increase", "demand_equity",
      "combined_pessimistic", "combined_investment"),
    family = c(
      "reference", "retirement", "retirement", "retirement",
      "entry", "entry", "fte",
      "demand", "demand", "demand",
      "composite", "composite"),
    label = c(
      "Baseline",
      "Retirement 2 years earlier",
      "Retirement 5 years earlier",
      "Retirement 2 years later",
      "Fellowship output +10%",
      "Fellowship output constrained (-10%)",
      "Reduced late-career clinical FTE",
      "Increased insurance coverage (+10pp uninsured -> insured)",
      "Increased obesity prevalence (+5 percentage points by 2035)",
      "Reduced access barriers (equity: income + race + insurance convergence)",
      "Combined pessimistic",
      "Combined workforce investment"),
    entrant_multiplier        = c(1.00, 1.00, 1.00, 1.00, 1.10, 0.90, 1.00, 1.00, 1.00, 1.00, 0.90, 1.10),
    retirement_shift_years    = c(0L,  -2L,  -5L,   2L,   0L,   0L,   0L,   0L,   0L,   0L,  -2L,   2L),
    late_career_fte_factor    = c(1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.75, 1.00, 1.00, 1.00, 0.75, 1.00),
    late_career_fte_onset_age = c(NA,   NA,   NA,   NA,   NA,   NA,   60L,  NA,   NA,   NA,   60L,  NA),
    demand_obesity_prev_shift     = c(0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  5.0,  0.0,  0.0,  0.0),
    demand_insurance_expansion_factor = c(1.0, 1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.2,  1.0,  1.1,  1.0,  1.0),
    requires_fte_model    = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,  FALSE, FALSE, FALSE, TRUE,  FALSE),
    requires_demand_model = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,  TRUE,  TRUE,  FALSE, FALSE),
    description = c(
      "Reference projection: observed retirement hazards, entrants held at the modelled rate, and no late-career FTE or demand adjustment. Every other scenario is stated as a perturbation of this origin.",
      "Retirement-hazard curve shifted 2 years earlier (physicians exit sooner).",
      "Retirement-hazard curve shifted 5 years earlier (a stress test on exit timing).",
      "Retirement-hazard curve shifted 2 years later (physicians work longer).",
      "Annual entrants scaled by 1.10 -- a 10% expansion of fellowship output.",
      "Annual entrants scaled by 0.90 -- a 10% contraction of fellowship output.",
      "Clinical FTE multiplied by 0.75 from age 60 onward, layered on top of headcount (requires the age-specific clinical-FTE model; see Phase 3 / CHARTER).",
      "Demand scenario: insurance_expansion_factor = 1.2, representing a 10pp shift from uninsured to insured status in the URPS-relevant population. Requires calibrated demand equations.",
      "Demand scenario: obesity_prev_shift = +5 percentage points above baseline by 2035, increasing pelvic floor disorder prevalence and visit rates. Requires calibrated demand equations.",
      "Demand scenario: equity convergence -- income, race, and insurance barriers reduced toward population mean (insurance_expansion_factor = 1.1). Requires calibrated demand equations.",
      "Combined pessimistic: retirement 2 years earlier AND fellowship constrained AND reduced late-career FTE.",
      "Combined workforce investment: retirement 2 years later AND fellowship output +10%."),
    stringsAsFactors = FALSE)
}

# ---- load-time validation (fail loud, mirrors geography.R) -------------------
local({
  d <- .urps_scenarios_df()
  supply_lever_cols <- c("entrant_multiplier", "retirement_shift_years",
                         "late_career_fte_factor", "late_career_fte_onset_age")
  demand_lever_cols <- c("demand_obesity_prev_shift", "demand_insurance_expansion_factor")
  b <- d[d$scenario_id == "baseline", ]
  stopifnot(
    "scenario_id must be unique, non-empty" =
      !anyDuplicated(d$scenario_id) && all(nzchar(d$scenario_id)),
    "every family must be a known family" =
      all(d$family %in% .urps_scenario_families),
    "exactly one 'reference' (baseline) scenario" =
      sum(d$family == "reference") == 1L && d$scenario_id[d$family == "reference"] == "baseline",
    "baseline must be the neutral supply lever origin" =
      b$entrant_multiplier == 1 && b$retirement_shift_years == 0L &&
      b$late_career_fte_factor == 1 && is.na(b$late_career_fte_onset_age),
    "baseline must be the neutral demand lever origin" =
      b$demand_obesity_prev_shift == 0.0 && b$demand_insurance_expansion_factor == 1.0,
    "entrant_multiplier, late_career_fte_factor, and demand_insurance_expansion_factor must be positive" =
      all(d$entrant_multiplier > 0) && all(d$late_career_fte_factor > 0) &&
      all(d$demand_insurance_expansion_factor > 0),
    "an FTE adjustment (factor != 1) needs an onset age, and vice versa" =
      all((d$late_career_fte_factor != 1) == !is.na(d$late_career_fte_onset_age)),
    "requires_fte_model iff the scenario adjusts FTE" =
      all(d$requires_fte_model == (d$late_career_fte_factor != 1)),
    "requires_demand_model iff the scenario uses a demand lever" =
      all(d$requires_demand_model == (
        d$demand_obesity_prev_shift != 0 | d$demand_insurance_expansion_factor != 1.0)),
    "demand scenarios must belong to the 'demand' family" =
      all(d$family[d$requires_demand_model] == "demand"),
    "composite family iff the scenario has registered components" =
      setequal(d$scenario_id[d$family == "composite"], names(.urps_scenario_components))
  )
  # composites must reconstruct from their components (demand levers neutral in current composites)
  for (cid in names(.urps_scenario_components)) {
    comp <- .urps_scenario_components[[cid]]
    if (!all(comp %in% d$scenario_id))
      stop(sprintf("[urps_scenarios] composite '%s' references unknown component(s): %s",
                   cid, paste(setdiff(comp, d$scenario_id), collapse = ", ")), call. = FALSE)
    cr <- d[match(comp, d$scenario_id), , drop = FALSE]
    onset <- cr$late_career_fte_onset_age[!is.na(cr$late_career_fte_onset_age)]
    expect <- data.frame(
      entrant_multiplier        = prod(cr$entrant_multiplier),
      retirement_shift_years    = as.integer(sum(cr$retirement_shift_years)),
      late_career_fte_factor    = prod(cr$late_career_fte_factor),
      late_career_fte_onset_age = if (length(onset)) as.integer(min(onset)) else NA_integer_,
      demand_obesity_prev_shift          = sum(cr$demand_obesity_prev_shift),
      demand_insurance_expansion_factor  = prod(cr$demand_insurance_expansion_factor))
    got <- d[d$scenario_id == cid, names(expect)]
    if (!isTRUE(all.equal(as.list(got), as.list(expect))))
      stop(sprintf("[urps_scenarios] composite '%s' lever values disagree with its components %s.",
                   cid, paste(comp, collapse = " + ")), call. = FALSE)
  }
})

# ---- exported API -----------------------------------------------------------

#' Version of the URPS scenario registry
#'
#' @description The semantic version of the scenario dictionary served by this
#'   package. Bump it whenever a scenario is added, removed, or its lever
#'   definition changes, so a downstream projection table can record exactly which
#'   registry it was built against.
#' @format Length-1 character string (e.g. `"1.0.0"`).
#' @seealso [urps_scenarios()], [urps_scenario()]
#' @family URPS scenarios
#' @examples
#' URPS_SCENARIO_REGISTRY_VERSION
#' @export
URPS_SCENARIO_REGISTRY_VERSION <- .URPS_SCENARIO_REGISTRY_VERSION

#' The URPS workforce scenario dictionary
#'
#' @description The single, versioned vocabulary of named forward-projection
#'   scenarios for the URPS workforce. Each row fixes the **lever values** that
#'   define what a scenario *means* -- everyone who writes or reads a projection
#'   keyed on `scenario_id` agrees on the same definition. This is the enum the
#'   cliff -> mufflyaccess projection contract uses, and it replaces the previously
#'   disjoint scenario sets scattered across the consumer repos.
#'
#' @details mufflyaccess owns the **definitions**, not the model: the registry
#'   states that (for example) `fellowship_plus_10pct` scales entrants by 1.10, but
#'   *how* an entrant multiplier, a retirement-hazard shift, or a late-career FTE
#'   factor propagates through the projection is cliff's engine (see
#'   `ARCHITECTURE.md`). Scenarios live in a four-axis lever space with `baseline`
#'   as the neutral origin; composite scenarios are the multiplicative/additive
#'   composition of single-lever components and are cross-checked at load so the
#'   table cannot drift. FTE scenarios carry `requires_fte_model = TRUE` because
#'   they depend on the age-specific clinical-FTE model that is a later phase --
#'   a consumer can filter to what it can execute today.
#'
#' @return A `data.frame`, one row per scenario, with columns:
#'   \describe{
#'     \item{scenario_id}{the stable identifier (the enum value)}
#'     \item{family}{`"reference"`, `"retirement"`, `"entry"`, `"fte"`, or
#'       `"composite"`}
#'     \item{label}{human-readable name}
#'     \item{entrant_multiplier}{scales annual entrants (1 = baseline)}
#'     \item{retirement_shift_years}{integer years to shift the retirement-hazard
#'       curve (negative = earlier exit; 0 = baseline)}
#'     \item{late_career_fte_factor}{multiplies clinical FTE at/after the onset age
#'       (1 = no adjustment)}
#'     \item{late_career_fte_onset_age}{age at which the FTE factor begins, or `NA`}
#'     \item{requires_fte_model}{`TRUE` if the scenario needs the clinical-FTE
#'       model (a later phase) to be executed}
#'     \item{description}{one-line statement of the scenario}
#'   }
#' @seealso [urps_scenario()], [urps_scenario_ids()], [is_urps_scenario()],
#'   [validate_urps_scenarios()], [URPS_SCENARIO_REGISTRY_VERSION]
#' @family URPS scenarios
#' @examples
#' urps_scenarios()[, c("scenario_id", "family", "label")]
#' # the executable-today subset (no clinical-FTE model required):
#' subset(urps_scenarios(), !requires_fte_model, scenario_id)
#' @export
urps_scenarios <- function() .urps_scenarios_df()

#' One scenario's definition
#'
#' @description Look up a single scenario by id and return its full definition as a
#'   labelled list, so a caller never passes around a bare `scenario_id` without its
#'   lever meaning. Unknown ids are a hard error listing the valid ids.
#' @param scenario_id A single registered scenario id (see [urps_scenario_ids()]).
#' @return A named list: the row's fields (`scenario_id`, `family`, `label`, the
#'   four lever fields, `requires_fte_model`, `description`) plus `components` -- the
#'   character vector of component scenario ids for a `composite`, or `NULL`
#'   otherwise -- and `registry_version`.
#' @seealso [urps_scenarios()], [validate_urps_scenarios()]
#' @family URPS scenarios
#' @examples
#' urps_scenario("fellowship_plus_10pct")
#' urps_scenario("combined_pessimistic")$components
#' try(urps_scenario("no_such_scenario"))  # hard error
#' @export
urps_scenario <- function(scenario_id) {
  if (!is.character(scenario_id) || length(scenario_id) != 1L || is.na(scenario_id))
    stop("[urps_scenario] `scenario_id` must be a single string.", call. = FALSE)
  d <- .urps_scenarios_df()
  i <- match(scenario_id, d$scenario_id)
  if (is.na(i))
    stop(sprintf("[urps_scenario] unknown scenario_id '%s'; use one of %s.",
                 scenario_id, paste(d$scenario_id, collapse = ", ")), call. = FALSE)
  out <- as.list(d[i, , drop = FALSE])
  out$components <- .urps_scenario_components[[scenario_id]]   # NULL unless composite
  out$registry_version <- .URPS_SCENARIO_REGISTRY_VERSION
  out
}

#' The registered scenario ids (the enum)
#'
#' @description The character vector of valid `scenario_id` values -- the domain a
#'   consumer validates its projection scenarios against.
#' @return A character vector of scenario ids.
#' @seealso [urps_scenarios()], [is_urps_scenario()], [validate_urps_scenarios()]
#' @family URPS scenarios
#' @examples
#' urps_scenario_ids()
#' @export
urps_scenario_ids <- function() .urps_scenarios_df()$scenario_id

#' Is a value a registered scenario id? (vectorised predicate)
#'
#' @description A non-erroring, vectorised membership test against the registry --
#'   the building block for a fail-loud guard or a filter.
#' @param x A character vector of candidate ids.
#' @return A logical vector the same length as `x` (`NA` in, `FALSE` out).
#' @seealso [validate_urps_scenarios()], [urps_scenario_ids()]
#' @family URPS scenarios
#' @examples
#' is_urps_scenario(c("baseline", "typo", NA))  # TRUE FALSE FALSE
#' @export
is_urps_scenario <- function(x) {
  if (!is.character(x)) x <- as.character(x)
  !is.na(x) & x %in% .urps_scenarios_df()$scenario_id
}

#' Validate that scenarios are registered (fail loud)
#'
#' @description Guard for a consumer's projection output: assert that every
#'   `scenario_id` used is defined in this registry, so an ad-hoc or misspelled
#'   scenario can never silently enter a published projection table. Accepts either
#'   a character vector of ids or a `data.frame` carrying a `scenario_id` column.
#' @param x A character vector of scenario ids, or a `data.frame` with a
#'   `scenario_id` column.
#' @return Invisibly `TRUE`; otherwise stops, naming the unregistered id(s).
#' @seealso [is_urps_scenario()], [urps_scenario_ids()], [urps_scenarios()]
#' @family URPS scenarios
#' @examples
#' validate_urps_scenarios(c("baseline", "fellowship_plus_10pct"))
#' validate_urps_scenarios(data.frame(scenario_id = "retire_2yr_earlier", value = 1))
#' try(validate_urps_scenarios("earlier_retirement"))  # not a registered id
#' @export
validate_urps_scenarios <- function(x) {
  ids <- if (is.data.frame(x)) {
    if (!"scenario_id" %in% names(x))
      stop("[validate_urps_scenarios] data.frame has no `scenario_id` column.", call. = FALSE)
    as.character(x$scenario_id)
  } else if (is.character(x)) x else
    stop("[validate_urps_scenarios] `x` must be a character vector or a data.frame with a `scenario_id` column.",
         call. = FALSE)
  if (!length(ids))
    stop("[validate_urps_scenarios] no scenario_id values to validate.", call. = FALSE)
  bad <- unique(ids[!is_urps_scenario(ids)])
  if (length(bad))
    stop(sprintf("[validate_urps_scenarios] unregistered scenario_id(s): %s. Valid ids: %s.",
                 paste(bad, collapse = ", "),
                 paste(urps_scenario_ids(), collapse = ", ")), call. = FALSE)
  invisible(TRUE)
}
