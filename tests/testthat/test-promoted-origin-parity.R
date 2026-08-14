# Promoted functions must still behave like the copy they were promoted from.
#
# canon_npi() and standardize_state_name() were promoted here so isochrones,
# cliff and twostep would share ONE definition -- but isochrones still carries
# its own copies (R/join_standards.R, R/utils_standardized.R). Two live
# implementations of a single source of truth is exactly the drift this package
# exists to prevent, and nothing was comparing them.
#
# They agree today: the sources differ only in `stringr::` qualification. This
# guards the behaviour rather than the text, so reformatting is free and a real
# change in either copy fails loudly.
#
# Needs an isochrones checkout, so it skips unless MUFFLYACCESS_ISOCHRONES_DIR
# points at one. The isochrones-integration workflow sets it; to run locally,
# clone isochrones and point the variable at it.

isochrones_dir <- function() {
  d <- Sys.getenv("MUFFLYACCESS_ISOCHRONES_DIR", "")
  if (!nzchar(d) || !dir.exists(d)) return(NULL)
  d
}

# Source one origin file into its own environment. The origin files are plain
# scripts, so this loads their definitions without needing isochrones installed.
# Returns the error instead of swallowing it: once a checkout IS provided, a
# failure to load must be visible rather than turning into a skip.
load_origin <- function(dir, relpath) {
  path <- file.path(dir, relpath)
  if (!file.exists(path))
    return(list(env = NULL, error = paste0(relpath, " not found under ", dir)))
  env <- new.env(parent = globalenv())
  err <- tryCatch({
    suppressWarnings(suppressMessages(source(path, local = env)))
    NULL
  }, error = function(e) conditionMessage(e))
  if (is.null(err)) list(env = env, error = NULL) else list(env = NULL, error = err)
}

# A guard that quietly disables itself is worse than no guard: it reports green
# while checking nothing. So the ONLY legitimate skip is "no checkout supplied"
# (local runs). Once MUFFLYACCESS_ISOCHRONES_DIR is set, every other problem --
# unreadable file, missing dependency, function gone -- is a failure.
require_origin <- function(dir, relpath, fn) {
  loaded <- load_origin(dir, relpath)
  if (is.null(loaded$env))
    fail(paste0("MUFFLYACCESS_ISOCHRONES_DIR is set to '", dir, "' but ",
                relpath, " could not be loaded: ", loaded$error,
                ". The parity guard must not silently disable itself -- install ",
                "what the origin file needs, or correct the path."))
  else if (!is.function(loaded$env[[fn]]))
    fail(paste0("isochrones ", relpath, " no longer defines ", fn, "(). If the ",
                "duplicate copy was removed, the promotion is finally complete ",
                "-- delete this guard deliberately rather than leaving it green ",
                "and inert."))
  loaded$env
}

# Compare on values AND on error behaviour: a guard that stopped failing loudly
# would be a silent behaviour change, and comparing return values alone would
# miss it.
#
# Warnings are muffled rather than compared. The isochrones copy calls
# beepr::beep() on some paths, which warns on a headless machine ("beep() could
# not play the sound") -- and only on the FIRST call, so treating it as the
# outcome made this comparison depend on audio hardware and on which test ran
# first. Returned values and error behaviour are the contract here; an audio
# side effect is not.
outcome_of <- function(f, ...) {
  withCallingHandlers(
    tryCatch(list(kind = "value", value = f(...)),
             error = function(e) list(kind = "error", msg = conditionMessage(e))),
    warning = function(w) invokeRestart("muffleWarning")
  )
}

NPI_CASES <- list(
  "1234567890",                      # canonical
  "123-456-7890",                    # dashes
  "123 456 7890",                    # spaces
  "123.456.7890",                    # dots
  "0000000001",                      # leading zeros preserved
  "1234567",                         # short: left-pad to 10
  "12345678901",                     # too long
  "12345abcde",                      # non-numeric
  "",                                # empty
  NA_character_,                     # NA
  c("1234567890", NA, "123-456-7890", "bad"),   # mixed vector
  character(0),                      # zero length
  1234567890                         # numeric input, not character
)

STATE_CASES <- list(
  "Colorado", "colorado", "  Colorado  ", "CO", "co",
  "District of Columbia", "DC",
  "Puerto Rico", "PR",
  "Notastate", "", NA_character_,
  c("Colorado", "CO", NA, "Notastate"),
  character(0)
)

test_that("canon_npi() matches the isochrones copy it was promoted from", {
  dir <- isochrones_dir()
  skip_if(is.null(dir), "set MUFFLYACCESS_ISOCHRONES_DIR to an isochrones checkout")
  env <- require_origin(dir, file.path("R", "join_standards.R"), "canon_npi")

  for (x in NPI_CASES) {
    mine   <- outcome_of(mufflyaccess::canon_npi, x, verbose = FALSE)
    theirs <- outcome_of(env$canon_npi,           x, verbose = FALSE)
    expect_identical(
      mine, theirs,
      info = paste0("canon_npi disagrees with the isochrones copy for input: ",
                    paste(utils::capture.output(dput(x)), collapse = " "))
    )
  }
})

test_that("standardize_state_name() matches the isochrones copy it was promoted from", {
  dir <- isochrones_dir()
  skip_if(is.null(dir), "set MUFFLYACCESS_ISOCHRONES_DIR to an isochrones checkout")
  env <- require_origin(dir, file.path("R", "utils_standardized.R"),
                        "standardize_state_name")

  for (x in STATE_CASES) {
    for (out in c("name", "abbr")) {
      mine   <- outcome_of(mufflyaccess::standardize_state_name, x, output = out)
      theirs <- outcome_of(env$standardize_state_name,           x, output = out)
      expect_identical(
        mine, theirs,
        info = paste0("standardize_state_name(output=", out,
                      ") disagrees with the isochrones copy for input: ",
                      paste(utils::capture.output(dput(x)), collapse = " "))
      )
    }
  }
})
