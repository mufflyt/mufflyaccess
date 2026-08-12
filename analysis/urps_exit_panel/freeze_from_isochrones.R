#!/usr/bin/env Rscript
# =============================================================================
# freeze_from_isochrones.R
#
# The isochrones -> mufflyaccess HANDOFF: validate the observed exit artifacts
# produced by isochrones (scripts/urps_exit_hazard/build_urps_exit_hazard.R) and
# freeze them where the mufflyaccess serving layer can read them -- then, only
# when the data is genuinely observed, flip the served manifest to
# retirement_ascertainment = "observed".
#
# mufflyaccess never re-derives retirement; it only SERVES frozen facts. This
# script is the ingest gate: it round-trips both CSVs through the package's own
# readers (which enforce the serving contracts and fail loud on anything
# malformed), copies the validated files to a stable location, and prints the
# exact activation + cliff commands.
#
#   Inputs  (isochrones build output):
#     URPS_EXIT_HAZARD_CSV   -> urps_exit_hazard_by_age_year.csv
#     URPS_DEPARTURES_CSV    -> urps_observed_departures.csv
#   Destination:
#     URPS_FREEZE_DIR        -> where to place the validated copies (default:
#                               analysis/urps_exit_panel/frozen/)
#   Manifest flip (guarded):
#     MUFFLYACCESS_URPS_ARTIFACT_DIR -> the served artifact dir whose
#                               urps_manifest.json should be flipped to observed
#     URPS_CONFIRM_OBSERVED=1 -> REQUIRED to actually write the manifest flip;
#                               without it the script validates + freezes only and
#                               prints the patch it WOULD apply.
#
# Fail-loud everywhere. Refuses to mark the bundled synthetic EXAMPLE artifacts as
# observed. Changes no default on its own -- promotion stays a human decision.
# =============================================================================

`%||%` <- function(a, b) if (is.null(a) || !length(a) || (is.character(a) && !nzchar(a))) b else a

if (!requireNamespace("mufflyaccess", quietly = TRUE))
  stop("[freeze] mufflyaccess must be installed (it validates the artifacts).", call. = FALSE)
if (!requireNamespace("jsonlite", quietly = TRUE))
  stop("[freeze] jsonlite is required to read/patch the manifest.", call. = FALSE)

hazard_in <- Sys.getenv("URPS_EXIT_HAZARD_CSV", "")
dep_in    <- Sys.getenv("URPS_DEPARTURES_CSV", "")
freeze_dir <- Sys.getenv("URPS_FREEZE_DIR",
                         file.path("analysis", "urps_exit_panel", "frozen"))
artifact_dir <- Sys.getenv("MUFFLYACCESS_URPS_ARTIFACT_DIR", "")
confirm_observed <- nzchar(Sys.getenv("URPS_CONFIRM_OBSERVED", ""))

if (!nzchar(hazard_in) || !file.exists(hazard_in))
  stop(sprintf("[freeze] set URPS_EXIT_HAZARD_CSV to the isochrones hazard artifact (got '%s').",
               hazard_in), call. = FALSE)
if (!nzchar(dep_in) || !file.exists(dep_in))
  stop(sprintf("[freeze] set URPS_DEPARTURES_CSV to the isochrones departures artifact (got '%s').",
               dep_in), call. = FALSE)

message("[freeze] hazard artifact:    ", hazard_in)
message("[freeze] departures artifact: ", dep_in)

## ---- 1. refuse to launder the bundled synthetic EXAMPLES as observed ---------
.same_bytes <- function(a, b) {
  if (!file.exists(a) || !file.exists(b)) return(FALSE)
  isTRUE(all.equal(readLines(a, warn = FALSE), readLines(b, warn = FALSE)))
}
ex_haz <- system.file("extdata", "urps_exit_hazard_by_age_year_example.csv", package = "mufflyaccess")
ex_dep <- system.file("extdata", "urps_observed_departures_example.csv",      package = "mufflyaccess")
is_example <- .same_bytes(hazard_in, ex_haz) || .same_bytes(dep_in, ex_dep)
if (is_example && confirm_observed)
  stop("[freeze] refusing to mark the bundled SYNTHETIC example artifact as 'observed'. ",
       "Point URPS_EXIT_HAZARD_CSV / URPS_DEPARTURES_CSV at the real isochrones build output.",
       call. = FALSE)

## ---- 2. validate by round-tripping through the package readers ---------------
# Setting the options makes the serving functions read these exact files; the
# readers enforce the schema + bounds and error on anything malformed. So a clean
# return here IS the contract validation.
options(mufflyaccess.urps_exit_hazard_path = hazard_in,
        mufflyaccess.urps_departures_path  = dep_in)

hz <- mufflyaccess::urps_exit_hazard_by_age_year()
stopifnot(all(c("age","year","n_at_risk","n_exits","exit_hazard") %in% names(hz)))
message(sprintf("[freeze] hazard OK: %d age x year cells, years %d-%d, hazard in [%.4f, %.4f]",
                nrow(hz), min(hz$year), max(hz$year),
                min(hz$exit_hazard, na.rm = TRUE), max(hz$exit_hazard, na.rm = TRUE)))

dp <- mufflyaccess::urps_departures()
message(sprintf("[freeze] departures OK: %d confirmed exits, years %d-%d; %d evidenced-retired",
                nrow(dp), min(dp$exit_year), max(dp$exit_year),
                sum(dp$retirement_observed %in% TRUE)))

ec <- mufflyaccess::urps_exit_counts()
message(sprintf("[freeze] annual exit counts derive cleanly (%d years; n_departed %d-%d)",
                nrow(ec), min(ec$n_departed), max(ec$n_departed)))

## ---- 3. freeze the validated copies -----------------------------------------
dir.create(freeze_dir, showWarnings = FALSE, recursive = TRUE)
haz_out <- file.path(freeze_dir, "urps_exit_hazard_by_age_year.csv")
dep_out <- file.path(freeze_dir, "urps_observed_departures.csv")
file.copy(hazard_in, haz_out, overwrite = TRUE)
file.copy(dep_in,    dep_out, overwrite = TRUE)
message("[freeze] froze validated copies -> ", normalizePath(freeze_dir))

## ---- 4. manifest flip (guarded) ---------------------------------------------
manifest_patch <- list(
  retirement_ascertainment    = "observed",
  retirement_definition       = "observed_workforce_exit",
  retirement_panel_resolution = "provider_year",
  exit_confirmation_months    = 12L)

emit_patch <- function() {
  message("[freeze] manifest fields to set (urps_manifest.json in the served artifact dir):")
  for (k in names(manifest_patch)) message(sprintf("    %-27s : %s", k, manifest_patch[[k]]))
}

if (!confirm_observed) {
  message("[freeze] DRY RUN (URPS_CONFIRM_OBSERVED unset): validated + froze, manifest NOT changed.")
  emit_patch()
} else if (!nzchar(artifact_dir)) {
  message("[freeze] URPS_CONFIRM_OBSERVED set but MUFFLYACCESS_URPS_ARTIFACT_DIR is unset; ",
          "cannot locate urps_manifest.json to flip. Set it, or apply the patch by hand:")
  emit_patch()
} else {
  mpath <- file.path(artifact_dir, "urps_manifest.json")
  if (!file.exists(mpath))
    stop("[freeze] no urps_manifest.json at ", mpath, call. = FALSE)
  m <- jsonlite::read_json(mpath, simplifyVector = TRUE)
  for (k in names(manifest_patch)) m[[k]] <- manifest_patch[[k]]
  jsonlite::write_json(m, mpath, auto_unbox = TRUE, pretty = TRUE, null = "null")
  message("[freeze] flipped ", mpath, " to retirement_ascertainment = 'observed'.")
  # prove the package now agrees
  st <- tryCatch(mufflyaccess::urps_retirement_status(), error = function(e) conditionMessage(e))
  message("[freeze] mufflyaccess::urps_retirement_status() -> ", st)
}

## ---- 5. activation instructions ---------------------------------------------
message("")
message("Activate the served artifacts:")
message(sprintf("  options(mufflyaccess.urps_exit_hazard_path = \"%s\")", haz_out))
message(sprintf("  options(mufflyaccess.urps_departures_path  = \"%s\")", dep_out))
message("  # or the env vars MUFFLYACCESS_URPS_EXIT_HAZARD / MUFFLYACCESS_URPS_DEPARTURES")
message("Then run cliff on the observed hazard:")
message("  CLIFF_RETIREMENT_SOURCE=observed_hazard Rscript scripts/urps_projection/build_urps_projection.R")
message("  # promote observed_hazard to the DEFAULT only after the isochrones back-test")
message("  # (backtest_retirement_source.R) beats the frozen curve on RMSE AND coverage.")
