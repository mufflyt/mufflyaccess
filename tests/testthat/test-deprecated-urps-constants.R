library(testthat)
test_that("ambiguous 2025 constants are deprecated", {
  expect_warning(
    value_abog <- mufflyaccess::URPS_COUNT_ABOG_ONLY_2025,
    "deprecated|urps_count"
  )
  expect_warning(
    value_combined <- mufflyaccess::URPS_COUNT_ABOG_PLUS_ABU_2025,
    "deprecated|urps_count"
  )
  expect_equal(value_abog, 1031L)
  expect_equal(value_combined, 1339L)
})

# Count only the deprecation warnings, so an unrelated warning from the
# inspection tool itself cannot turn this into a spurious failure.
n_deprecation_warnings <- function(expr) {
  n <- 0L
  withCallingHandlers(
    force(expr),
    warning = function(w) {
      if (grepl("is deprecated", conditionMessage(w), fixed = TRUE)) {
        n <<- n + 1L
        invokeRestart("muffleWarning")
      }
    }
  )
  n
}

test_that("namespace introspection does not fire the deprecation warning", {
  # `R CMD check` fetches every binding in the namespace (codoc(), checkFF(),
  # checkS3methods(), codetools::checkUsagePackage()) to see which are
  # functions. Those fetches hit the active bindings, and check reports any
  # pass that emits output -- which turned an unasked-for deprecation notice
  # into 2 permanent WARNINGs and 2 NOTEs that masked real findings.
  # inspecting_namespace() in R/zzz.R keeps introspection quiet; the test above
  # covers the other half, that real use still warns.
  # tools:: introspection library()s the package, which only works against a
  # real installed copy -- under pkgload/load_all() the dev namespace shadows
  # it and codoc() errors. This runs under R CMD check, which is where the
  # regression would actually show up.
  skip_if(
    exists(".__DEVTOOLS__",
      envir = asNamespace("mufflyaccess"),
      inherits = FALSE
    ),
    "package is dev-loaded (load_all); needs a real install"
  )

  expect_equal(n_deprecation_warnings(tools::codoc("mufflyaccess")), 0L)
  expect_equal(n_deprecation_warnings(tools::checkFF("mufflyaccess")), 0L)
  expect_equal(n_deprecation_warnings(tools::checkS3methods("mufflyaccess")), 0L)
})
