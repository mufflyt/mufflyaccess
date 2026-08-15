# Promoted functions must still match the copy they were promoted from.
#
# canon_npi() and standardize_state_name() were promoted here so isochrones,
# cliff and twostep would share ONE definition -- but isochrones still carries
# its own copies (R/join_standards.R, R/utils_standardized.R). Two live
# implementations of a single source of truth is exactly the drift this package
# exists to prevent, and nothing was comparing them.
#
# HOW THIS COMPARES, AND WHY
#
# It compares PARSED SOURCE, not behaviour. Calling the origin copies was tried
# first and is structurally fragile: the origin files are scripts, not a
# package, so sourcing one in isolation pulls in whatever else isochrones had
# in scope. On a clean runner that fails outright ("could not find function
# 'f'"), and on a developer machine it appears to work only because the ambient
# library happens to supply the difference. A guard whose verdict depends on
# what is installed is not a guard.
#
# Parsing executes nothing, so it is identical everywhere. Both sides are
# deparsed, which canonicalises formatting and drops comments, and `pkg::`
# qualification is stripped -- that being the one difference the two copies
# genuinely have today (mufflyaccess qualifies `stringr::`, isochrones relies on
# attachment). What survives is the logic. A real change on either side fails;
# reindenting or recommenting does not.
#
# Needs an isochrones checkout. That is the ONLY reason this may skip -- once
# MUFFLYACCESS_ISOCHRONES_DIR is set, every other problem is a failure, because
# a guard that quietly disables itself reports green while checking nothing.

isochrones_dir <- function() {
  d <- Sys.getenv("MUFFLYACCESS_ISOCHRONES_DIR", "")
  if (!nzchar(d) || !dir.exists(d)) {
    return(NULL)
  }
  d
}

# Console and audio instrumentation is not logic. The isochrones copies carry
# cat("[INFO] ...") tracing and maybe_beep() calls that were deliberately
# dropped on promotion -- a library should not print or beep. That divergence is
# intended and permanent, so comparing it would leave this guard failing forever
# on a difference nobody wants removed. Stripped from BOTH sides so what is
# compared is the logic.
SIDE_EFFECT_CALLS <- c(
  "cat", "message", "print", "beep", "maybe_beep",
  "packageStartupMessage", "flush.console"
)

strip_side_effects <- function(e) {
  if (!is.call(e)) {
    return(e)
  }
  head <- as.character(e[[1L]])[1L]
  if (identical(head, "function")) {
    # element 2 is the formals pairlist and must not be walked; element 3 is
    # the body, which is the whole point.
    e[[3L]] <- strip_side_effects(e[[3L]])
    return(e)
  }
  if (identical(head, "{")) {
    body_exprs <- as.list(e)[-1L]
    keep <- Filter(function(x) {
      !(is.call(x) && as.character(x[[1L]])[1L] %in% SIDE_EFFECT_CALLS)
    }, body_exprs)
    return(as.call(c(list(as.name("{")), lapply(keep, strip_side_effects))))
  }
  as.call(lapply(as.list(e), strip_side_effects))
}

# Pull one top-level `name <- function(...)` definition out of a file, without
# evaluating anything in it.
fn_source <- function(path, name) {
  if (!file.exists(path)) {
    return(NULL)
  }
  exprs <- tryCatch(parse(path), error = function(e) NULL)
  if (is.null(exprs)) {
    return(NULL)
  }
  for (e in exprs) {
    if (is.call(e) && length(e) == 3L &&
      as.character(e[[1L]])[1L] %in% c("<-", "=") &&
      is.name(e[[2L]]) && identical(as.character(e[[2L]]), name) &&
      is.call(e[[3L]]) && identical(as.character(e[[3L]][[1L]])[1L], "function")) {
      return(paste(deparse(strip_side_effects(e[[3L]])), collapse = "\n"))
    }
  }
  NULL
}

# Canonicalise away the differences that are not behaviour: namespace
# qualification and whitespace. deparse() has already normalised layout and
# removed comments.
normalize_fn <- function(src) {
  src <- gsub("[A-Za-z][A-Za-z0-9._]*::", "", src)
  src <- gsub("[[:space:]]+", " ", src)
  trimws(src)
}

compare_promoted <- function(fn, origin_relpath, here_relpath) {
  dir <- isochrones_dir()
  skip_if(is.null(dir), "set MUFFLYACCESS_ISOCHRONES_DIR to an isochrones checkout")

  origin_path <- file.path(dir, origin_relpath)
  theirs <- fn_source(origin_path, fn)
  mine <- fn_source(test_path("..", "..", here_relpath), fn)

  # Once a checkout is supplied, anything other than a clean comparison is a
  # failure -- never a skip.
  if (is.null(mine)) {
    fail(paste0(
      "could not find ", fn, "() in this package's ", here_relpath,
      " -- the parity guard cannot verify what it cannot parse."
    ))
    return(invisible(NULL))
  }
  if (is.null(theirs)) {
    fail(paste0(
      "could not find ", fn, "() in isochrones ", origin_relpath,
      " (looked in '", origin_path, "'). If isochrones removed its ",
      "duplicate copy the promotion is finally complete -- delete ",
      "this guard deliberately rather than leaving it green and inert."
    ))
    return(invisible(NULL))
  }

  expect_identical(
    normalize_fn(mine), normalize_fn(theirs),
    info = paste0(
      fn, "() has diverged from the isochrones copy it was promoted from. ",
      "Two implementations of an SSOT function is the drift this package ",
      "exists to prevent: reconcile them, or retire the isochrones copy."
    )
  )
}

test_that("canon_npi() matches the isochrones copy it was promoted from", {
  compare_promoted(
    "canon_npi",
    file.path("R", "join_standards.R"),
    file.path("R", "npi.R")
  )
})

test_that("standardize_state_name() matches the isochrones copy it was promoted from", {
  compare_promoted(
    "standardize_state_name",
    file.path("R", "utils_standardized.R"),
    file.path("R", "state.R")
  )
})
