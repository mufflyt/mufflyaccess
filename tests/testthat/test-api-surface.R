# The exported surface of an SSOT is a cross-repo contract, not an internal
# detail. isochrones, cliff and twostep call into this package by name and each
# pins it by commit, so a rename or a dropped export does not fail here -- it
# fails inside a consumer as "could not find function", once that consumer next
# moves its pin, which may be many commits later. (Both consumers are currently
# 20 and 40 commits behind, so the lag is real.)
#
# api-surface.txt records the surface. Changes in either direction have to be
# deliberate and visible in review: a removal is a breaking change for three
# repositories, and an addition widens a contract others depend on.

surface_path <- function() test_path("api-surface.txt")

read_recorded_surface <- function(path = surface_path()) {
  lines <- readLines(path, warn = FALSE)
  lines <- trimws(lines)
  sort(lines[nzchar(lines) & !startsWith(lines, "#")])
}

test_that("the recorded surface file is well formed", {
  recorded <- read_recorded_surface()
  expect_gt(length(recorded), 0L)
  expect_false(anyDuplicated(recorded) > 0)
  expect_identical(recorded, sort(recorded))
})

test_that("no export has been removed or renamed", {
  recorded <- read_recorded_surface()
  current <- sort(getNamespaceExports("mufflyaccess"))
  removed <- setdiff(recorded, current)

  if (length(removed)) {
    fail(paste0(
      "These exports are gone from the public surface: ",
      paste(removed, collapse = ", "), ".\n",
      "isochrones, cliff and twostep call this package by name, so a removal or ",
      "rename breaks them at run time rather than here. If it is intended: bump ",
      "the version, add a NEWS entry saying what replaces it, update ",
      "tests/testthat/api-surface.txt, and open an issue on each consumer that ",
      "uses it."
    ))
  } else {
    succeed()
  }
})

test_that("no export has been added without recording it", {
  recorded <- read_recorded_surface()
  current <- sort(getNamespaceExports("mufflyaccess"))
  added <- setdiff(current, recorded)

  if (length(added)) {
    fail(paste0(
      "These exports are not in the recorded surface: ",
      paste(added, collapse = ", "), ".\n",
      "Adding to a shared contract should be visible in review. Regenerate with ",
      "Rscript -e 'writeLines(sort(getNamespaceExports(\"mufflyaccess\")))' > ",
      "tests/testthat/api-surface.txt (keeping the header), and describe the ",
      "addition in NEWS.md."
    ))
  } else {
    succeed()
  }
})

test_that("every recorded export actually resolves in the namespace", {
  # Guards against a stale record: a name can sit in the file while the object
  # behind it is gone, which would let the two tests above pass while
  # `mufflyaccess::thing` still errors for a consumer.
  recorded <- read_recorded_surface()
  ns <- asNamespace("mufflyaccess")
  missing <- recorded[!vapply(recorded, exists, logical(1),
    envir = ns, inherits = FALSE
  )]
  expect_identical(missing, character(0))
})
