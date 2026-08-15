# ==============================================================================
# The cliff -> mufflyaccess PROJECTION CONTRACT (see ARCHITECTURE.md / CHARTER).
#
# The second producer->SSOT contract, mirroring the isochrones count contract:
# cliff RUNS the workforce projection engine and emits a long, frozen projection
# table; mufflyaccess VALIDATES it (schema + registered scenarios + internal
# consistency + a tie back to the served count) and can serve it. mufflyaccess
# owns the contract shape and the checks; it never runs the projection model.
#
# The table is long -- one row per (year, scenario_id, specialty,
# certification_pathway, geography_type, geography_id) -- so a new scenario, year,
# pathway, or geography is a row, never a schema change. `scenario_id` is the enum
# from urps_scenarios(); the baseline-year starting stock must equal urps_count()
# so a projection can never silently start from a number the SSOT does not serve.
# ==============================================================================

.URPS_PROJECTION_CONTRACT_VERSION <- "1.1.0"

# the required long-table columns, in canonical order, with types + meaning
.urps_projection_schema <- function() {
  data.frame(
    column = c(
      "year", "scenario_id", "specialty", "certification_pathway",
      "geography_type", "geography_id", "supply_headcount", "supply_clinical_fte",
      "lower_95", "upper_95", "entrants", "exits", "net_change",
      "demand_clinical_fte", "gap_fte"
    ),
    type = c(
      "integer", "character", "character", "character",
      "character", "character", "double", "double",
      "double", "double", "double", "double", "double",
      "double", "double"
    ),
    optional = c(
      FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, TRUE,
      TRUE, TRUE, TRUE, TRUE, TRUE,
      TRUE, TRUE
    ),
    description = c(
      "projection year",
      "scenario id (must be registered in urps_scenarios())",
      "subspecialty label (e.g. \"URPS\")",
      "ABOG, ABU_NET_NEW, or ABOG_PLUS_ABU (the count-contract pathway vocab)",
      "national or conus (the count-contract geography vocab)",
      "geography identifier within geography_type (e.g. \"US\", \"CONUS\", a FIPS)",
      "projected supply headcount (point estimate)",
      "projected clinical FTE (NA until the age-specific FTE model exists; see CHARTER)",
      "lower 95% bound on supply_headcount (NA if deterministic)",
      "upper 95% bound on supply_headcount (NA if deterministic)",
      "entrants into the stock during the year",
      "exits from the stock during the year",
      "net change in the stock during the year (defined as entrants - exits)",
      "projected demand in clinical FTE units (NA until demand equations calibrated; see urps_demand_params())",
      "gap_fte = demand_clinical_fte - supply_clinical_fte; negative = surplus, positive = shortage (NA unless both demand and supply FTE present)"
    ),
    stringsAsFactors = FALSE
  )
}

#' Version of the URPS projection contract
#'
#' @description The semantic version of the cliff -> mufflyaccess projection-table
#'   contract this package validates. Producers stamp it on their output so a
#'   served projection records exactly which contract it conforms to.
#' @format Length-1 character string (e.g. `"1.0.0"`).
#' @seealso [urps_projection_schema()], [validate_urps_projection()]
#' @family URPS projection
#' @examples
#' URPS_PROJECTION_CONTRACT_VERSION
#' @export
URPS_PROJECTION_CONTRACT_VERSION <- .URPS_PROJECTION_CONTRACT_VERSION

#' The URPS projection-table contract schema
#'
#' @description The column specification a cliff-produced projection table must
#'   satisfy: the canonical long-table columns, their types, whether each is
#'   optional, and what it means. A producer builds to this; [validate_urps_projection()]
#'   enforces it.
#' @return A `data.frame` with columns `column`, `type`, `optional`, `description`
#'   (one row per contract column, in canonical order).
#' @seealso [validate_urps_projection()], [read_urps_projection()],
#'   [URPS_PROJECTION_CONTRACT_VERSION]
#' @family URPS projection
#' @examples
#' urps_projection_schema()
#' @export
urps_projection_schema <- function() .urps_projection_schema()

#' Validate a URPS projection table against the contract (fail loud)
#'
#' @description Checks that a cliff-produced projection table conforms to the
#'   projection contract, failing loud with a specific message on the first
#'   violation. Verifies far more than column presence: every `scenario_id` is
#'   registered in [urps_scenarios()], the `baseline` scenario is present, the
#'   `certification_pathway` / `geography_type` values are the count-contract
#'   vocabularies, there are no duplicate series keys, the 95% bounds bracket the
#'   point estimate, counts are non-negative, and `net_change` reconciles as
#'   `entrants - exits`. Optionally ties the baseline-year starting stock back to
#'   [urps_count()] so a projection can never start from a number the SSOT does not
#'   serve.
#' @details Checks performed, each failing loud:
#'   \itemize{
#'     \item all required (non-optional) columns present;
#'     \item `scenario_id` values all registered ([validate_urps_scenarios()]) and
#'       the `baseline` scenario present;
#'     \item `certification_pathway` in ABOG / ABU_NET_NEW / ABOG_PLUS_ABU and
#'       `geography_type` in national / conus;
#'     \item no duplicate `(year, scenario_id, specialty, certification_pathway,
#'       geography_type, geography_id)` key;
#'     \item `supply_headcount` non-negative; where present, `entrants` / `exits`
#'       non-negative and `lower_95 <= supply_headcount <= upper_95`;
#'     \item where present, `0 <= supply_clinical_fte <= supply_headcount` (a head
#'       is at most 1.0 clinical FTE);
#'     \item where all three are present, `net_change == entrants - exits` (within
#'       `tol`);
#'     \item with `baseline_tie`, the `baseline`-scenario `supply_headcount` at the
#'       named year/geography/pathway equals [urps_count()] for the matching
#'       measure.
#'   }
#' @param x A projection `data.frame`, or a path to a CSV to read
#'   ([read_urps_projection()] is used).
#' @param baseline_tie Optional named list pinning the starting stock to the served
#'   count: `list(year=, measure=, geography_type=, certification_pathway=)`. The
#'   pathway must be `"ABOG"` or `"ABOG_PLUS_ABU"` (the two [urps_count()] exposes).
#' @param tol Numeric tolerance for the `net_change == entrants - exits` identity
#'   (default `1e-6`).
#' @return Invisibly `TRUE`; otherwise stops with the failed check.
#' @seealso [urps_projection_schema()], [read_urps_projection()],
#'   [validate_urps_scenarios()], [urps_count()]
#' @family URPS projection
#' @examples
#' p <- read_urps_projection(system.file(
#'   "extdata", "urps_projection_example.csv",
#'   package = "mufflyaccess"
#' ))
#' validate_urps_projection(p)
#' # tie the 2025 baseline stock to the served roster snapshot (1339):
#' validate_urps_projection(p, baseline_tie = list(
#'   year = 2025, measure = "roster_snapshot",
#'   geography_type = "national", certification_pathway = "ABOG_PLUS_ABU"
#' ))
#' @export
validate_urps_projection <- function(x, baseline_tie = NULL, tol = 1e-6) {
  d <- if (is.character(x) && length(x) == 1L) read_urps_projection(x, validate = FALSE) else x
  if (!is.data.frame(d)) {
    stop("[validate_urps_projection] `x` must be a data.frame or a path to a CSV.", call. = FALSE)
  }

  sch <- .urps_projection_schema()
  req <- sch$column[!sch$optional]
  miss <- setdiff(req, names(d))
  if (length(miss)) {
    stop("[validate_urps_projection] missing required column(s): ",
      paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  if (!nrow(d)) {
    stop("[validate_urps_projection] projection table is empty.", call. = FALSE)
  }

  # scenarios: registered + baseline present
  validate_urps_scenarios(as.character(d$scenario_id))
  if (!"baseline" %in% d$scenario_id) {
    stop("[validate_urps_projection] the 'baseline' scenario must be present.", call. = FALSE)
  }

  # controlled vocabularies (reuse the count-contract sets)
  bad_p <- setdiff(unique(d$certification_pathway), .urps_pathways)
  if (length(bad_p)) {
    stop("[validate_urps_projection] unknown certification_pathway: ",
      paste(bad_p, collapse = ", "),
      call. = FALSE
    )
  }
  bad_g <- setdiff(unique(d$geography_type), .urps_geographies)
  if (length(bad_g)) {
    stop("[validate_urps_projection] unknown geography_type: ",
      paste(bad_g, collapse = ", "),
      call. = FALSE
    )
  }

  # unique series key
  key <- paste(d$year, d$scenario_id, d$specialty, d$certification_pathway,
    d$geography_type, d$geography_id,
    sep = "|"
  )
  if (anyDuplicated(key)) {
    stop("[validate_urps_projection] duplicate (year, scenario_id, specialty, ",
      "certification_pathway, geography_type, geography_id) key.",
      call. = FALSE
    )
  }

  # numeric sanity
  sh <- suppressWarnings(as.numeric(d$supply_headcount))
  if (anyNA(sh)) {
    stop("[validate_urps_projection] supply_headcount must be a non-NA number in every row.", call. = FALSE)
  }
  if (any(sh < 0)) {
    stop("[validate_urps_projection] supply_headcount must be non-negative.", call. = FALSE)
  }
  for (col in c("entrants", "exits")) {
    if (col %in% names(d)) {
      v <- suppressWarnings(as.numeric(d[[col]]))
      if (any(!is.na(v) & v < 0)) {
        stop(sprintf("[validate_urps_projection] %s must be non-negative where present.", col), call. = FALSE)
      }
    }
  }
  # clinical FTE is bounded: non-negative and never more than the headcount it is
  # drawn from (a single head contributes at most 1.0 clinical FTE).
  if ("supply_clinical_fte" %in% names(d)) {
    fte <- suppressWarnings(as.numeric(d$supply_clinical_fte))
    if (any(!is.na(fte) & fte < 0)) {
      stop("[validate_urps_projection] supply_clinical_fte must be non-negative where present.", call. = FALSE)
    }
    if (any(!is.na(fte) & fte > sh)) {
      stop("[validate_urps_projection] supply_clinical_fte cannot exceed supply_headcount (a head is at most 1.0 clinical FTE).",
        call. = FALSE
      )
    }
  }

  # 95% bounds bracket the point estimate (where present)
  if (all(c("lower_95", "upper_95") %in% names(d))) {
    lo <- suppressWarnings(as.numeric(d$lower_95))
    up <- suppressWarnings(as.numeric(d$upper_95))
    ok <- is.na(lo) | is.na(up) | (lo <= sh & sh <= up)
    if (!all(ok)) {
      stop(sprintf(
        "[validate_urps_projection] 95%% bounds do not bracket supply_headcount in %d row(s).",
        sum(!ok)
      ), call. = FALSE)
    }
  }

  # flow identity: net_change == entrants - exits (where all present)
  if (all(c("entrants", "exits", "net_change") %in% names(d))) {
    e <- suppressWarnings(as.numeric(d$entrants))
    x2 <- suppressWarnings(as.numeric(d$exits))
    nc <- suppressWarnings(as.numeric(d$net_change))
    have <- !is.na(e) & !is.na(x2) & !is.na(nc)
    if (any(have & abs(nc - (e - x2)) > tol)) {
      stop("[validate_urps_projection] net_change must equal entrants - exits (flow identity).",
        call. = FALSE
      )
    }
  }

  # gap identity: gap_fte == demand_clinical_fte - supply_clinical_fte (where all present)
  if (all(c("demand_clinical_fte", "supply_clinical_fte", "gap_fte") %in% names(d))) {
    dem <- suppressWarnings(as.numeric(d$demand_clinical_fte))
    sup <- suppressWarnings(as.numeric(d$supply_clinical_fte))
    gap <- suppressWarnings(as.numeric(d$gap_fte))
    have_all <- !is.na(dem) & !is.na(sup) & !is.na(gap)
    if (any(have_all & abs(gap - (dem - sup)) > tol)) {
      stop("[validate_urps_projection] gap_fte must equal demand_clinical_fte - supply_clinical_fte.",
        call. = FALSE
      )
    }
  }

  # baseline-year tie back to the served count SSOT
  if (!is.null(baseline_tie)) {
    bt <- baseline_tie
    need <- c("year", "measure", "geography_type", "certification_pathway")
    if (!all(need %in% names(bt))) {
      stop("[validate_urps_projection] baseline_tie needs ", paste(need, collapse = ", "), ".", call. = FALSE)
    }
    if (!bt$certification_pathway %in% c("ABOG", "ABOG_PLUS_ABU")) {
      stop("[validate_urps_projection] baseline_tie certification_pathway must be ABOG or ABOG_PLUS_ABU ",
        "(the pathways urps_count() exposes).",
        call. = FALSE
      )
    }
    expected <- urps_count(bt$year, bt$measure, bt$geography_type,
      include_urology = identical(bt$certification_pathway, "ABOG_PLUS_ABU")
    )
    sel <- d$scenario_id == "baseline" & d$year == bt$year &
      d$geography_type == bt$geography_type & d$certification_pathway == bt$certification_pathway
    got <- unique(sh[sel])
    if (length(got) != 1L) {
      stop(sprintf(
        "[validate_urps_projection] baseline_tie found %d baseline rows for year %s / %s / %s (need exactly 1).",
        length(got), bt$year, bt$geography_type, bt$certification_pathway
      ), call. = FALSE)
    }
    if (as.integer(round(got)) != as.integer(expected)) {
      stop(sprintf(
        "[validate_urps_projection] baseline starting stock (%s) does not match urps_count() (%s) for %s/%s/%s.",
        got, expected, bt$year, bt$geography_type, bt$certification_pathway
      ), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Compute gap_fte from supply and demand clinical FTE
#'
#' @description Closes the supply/demand/gap triangle:
#'   `gap_fte = demand_clinical_fte - supply_clinical_fte`.
#'   Positive = shortage (demand exceeds supply); negative = surplus.
#'   Returns `NA_real_` if either argument is `NA` (i.e., when the demand model
#'   is not yet calibrated). This is the value that goes in the `gap_fte` column
#'   of the projection contract table.
#'
#' @details **Typical cliff usage (per projection row):**
#'   ```r
#'   supply_fte <- mufflyaccess::urps_supply_fte_sex(cohort, baseline_scale, ...)
#'   demand_fte <- mufflyaccess::urps_demand_fte(population, visits_per_fte,
#'                   scenario_id = scenario_id)
#'   gap_fte    <- mufflyaccess::urps_gap_fte(supply_fte, demand_fte)
#'   ```
#'   All three values go directly into the projection contract columns
#'   `supply_clinical_fte`, `demand_clinical_fte`, and `gap_fte`.
#'   [validate_urps_projection()] enforces the identity when all three are non-NA.
#'
#' @param supply_clinical_fte Length-1 numeric from [urps_supply_fte_sex()] (or
#'   `NA`).
#' @param demand_clinical_fte Length-1 numeric from [urps_demand_fte()] (or
#'   `NA`).
#' @return Length-1 numeric `gap_fte = demand - supply`, or `NA_real_` if either
#'   input is `NA`.
#' @seealso [urps_supply_fte_sex()], [urps_demand_fte()],
#'   [validate_urps_projection()]
#' @family URPS projection
#' @examples
#' urps_gap_fte(supply_clinical_fte = 1200, demand_clinical_fte = 1450) # +250 shortage
#' urps_gap_fte(supply_clinical_fte = 1400, demand_clinical_fte = 1200) # -200 surplus
#' urps_gap_fte(supply_clinical_fte = 1200, demand_clinical_fte = NA_real_) # NA
#' @export
urps_gap_fte <- function(supply_clinical_fte, demand_clinical_fte) {
  if (!is.numeric(supply_clinical_fte) || length(supply_clinical_fte) != 1L) {
    stop("[urps_gap_fte] `supply_clinical_fte` must be a length-1 numeric.", call. = FALSE)
  }
  if (!is.numeric(demand_clinical_fte) || length(demand_clinical_fte) != 1L) {
    stop("[urps_gap_fte] `demand_clinical_fte` must be a length-1 numeric.", call. = FALSE)
  }
  if (is.na(supply_clinical_fte) || is.na(demand_clinical_fte)) {
    return(NA_real_)
  }
  demand_clinical_fte - supply_clinical_fte
}

#' Read a URPS projection table (typed), optionally validating it
#'
#' @description Read a projection CSV into a typed `data.frame` (coercing `year` to
#'   integer and the numeric measure columns to double), then -- by default --
#'   validate it against the contract.
#' @param path Path to the projection CSV.
#' @param validate If `TRUE` (default), run [validate_urps_projection()] before
#'   returning.
#' @param ... Passed to [validate_urps_projection()] (e.g. `baseline_tie`).
#' @return The projection `data.frame`.
#' @seealso [validate_urps_projection()], [urps_projection_schema()]
#' @family URPS projection
#' @examples
#' f <- system.file("extdata", "urps_projection_example.csv", package = "mufflyaccess")
#' str(read_urps_projection(f))
#' @export
read_urps_projection <- function(path, validate = TRUE, ...) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || !file.exists(path)) {
    stop("[read_urps_projection] `path` must be a path to an existing CSV.", call. = FALSE)
  }
  d <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  if ("year" %in% names(d)) d$year <- as.integer(d$year)
  num <- c(
    "supply_headcount", "supply_clinical_fte", "lower_95", "upper_95",
    "entrants", "exits", "net_change", "demand_clinical_fte", "gap_fte"
  )
  for (col in intersect(num, names(d))) d[[col]] <- suppressWarnings(as.numeric(d[[col]]))
  if (isTRUE(validate)) validate_urps_projection(d, ...)
  d
}
