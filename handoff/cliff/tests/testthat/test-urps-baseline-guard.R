# test-urps-baseline-guard.R   [APPLY IN: cliff]
# Fails if (a) the baseline stops matching mufflyaccess, or (b) a hardcoded
# national URPS baseline literal is reintroduced anywhere in cliff source.

test_that("cliff baseline comes from mufflyaccess and matches the pinned values", {
  skip_if_not_installed("mufflyaccess")
  source(testthat::test_path("..", "..", "R", "urps_baseline.R"))
  expect_equal(urps_baseline(include_urology = FALSE), 1031L)
  expect_equal(urps_baseline(include_urology = TRUE),  1339L)
  # Pin: if a mufflyaccess bump changes these, THIS test fails and forces an
  # explicit, reviewed update rather than a silent drift.
  expect_equal(as.integer(mufflyaccess::urps_count(2023L, FALSE)), 1031L)
  expect_equal(as.integer(mufflyaccess::urps_count(2023L, TRUE)),  1339L)
})

test_that("cliff never hardcodes a national URPS baseline literal", {
  banned <- c("1031", "1339", "1295", "264", "308")
  roots  <- Filter(dir.exists, c(here::here("R"), here::here("code"),
                                 here::here("manuscript"), here::here("shiny_urps_scenarios"),
                                 here::here("shiny_urps_adequacy")))
  files  <- list.files(roots, pattern = "[.](R|r|Rmd)$", recursive = TRUE, full.names = TRUE)
  # allowlist: the shim itself, this test, archival material, and the historical
  # (non-authoritative) reconciliation doc may mention the numbers.
  files <- files[!basename(files) %in% c("urps_baseline.R", "test-urps-baseline-guard.R")]
  files <- files[!grepl("archive|archived|deprecated|SSOT_URPS_BASELINE_RECONCILIATION", files)]
  hits <- unlist(lapply(files, function(f) {
    ln <- readLines(f, warn = FALSE)
    m  <- grep(paste0("(?<![0-9.])(", paste(banned, collapse = "|"), ")(?![0-9.])"),
               ln, perl = TRUE)
    if (length(m)) sprintf("%s:%d: %s", f, m, trimws(ln[m])) else character(0)
  }))
  # NOTE: 264/308 can appear in unrelated contexts; curate the allowlist above if
  # a legitimate non-baseline use trips this. 1031/1339/1295 are the decisive ones.
  expect(length(hits) == 0L, paste0(
    "Hardcoded URPS baseline literal(s) found -- obtain the number from ",
    "mufflyaccess::urps_count() instead:\n", paste(hits, collapse = "\n")))
})
