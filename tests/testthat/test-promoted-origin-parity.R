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
load_origin <- function(dir, relpath) {
  path <- file.path(dir, relpath)
  if (!file.exists(path)) return(NULL)
  env <- new.env(parent = globalenv())
  ok <- tryCatch({
    suppressWarnings(suppressMessages(source(path, local = env)))
    TRUE
  }, error = function(e) FALSE)
  if (!ok) NULL else env
}

# Compare on values AND on error behaviour: a guard that stopped failing loudly
# would be a silent behaviour change, and comparing return values alone would
# miss it.
outcome_of <- function(f, ...) {
  tryCatch(list(kind = "value", value = f(...)),
           error   = function(e) list(kind = "error",   msg = conditionMessage(e)),
           warning = function(w) list(kind = "warning", msg = conditionMessage(w)))
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
  env <- load_origin(dir, file.path("R", "join_standards.R"))
  skip_if(is.null(env), "isochrones R/join_standards.R not sourceable")
  skip_if(!is.function(env$canon_npi), "isochrones no longer defines canon_npi")

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
  env <- load_origin(dir, file.path("R", "utils_standardized.R"))
  skip_if(is.null(env), "isochrones R/utils_standardized.R not sourceable")
  skip_if(!is.function(env$standardize_state_name),
          "isochrones no longer defines standardize_state_name")

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
