library(testthat)
library(mufflyaccess)

# The age distribution and the counts are two views of one cohort. If they ever
# disagree, one of the bundled artifacts is wrong and no caller should be handed
# either -- so most of these tests are reconciliation, not spot values.

test_that("the national distribution totals the published 2023 active count", {
  a <- urps_active_ages()
  expect_equal(sum(a$n_active),
               urps_count(2023L, "board_certified_active", "national", TRUE))
  expect_equal(sum(a$n_active), 1306L)   # NOT 1332 (retired v2.1.0), NOT 1339 (2025 roster)
})

test_that("each base pathway totals its own published count", {
  expect_equal(sum(urps_active_ages("ABOG")$n_active),
               urps_count(2023L, "board_certified_active", "national", FALSE))
  expect_equal(sum(urps_active_ages("ABOG")$n_active), 1027L)
  # ABU net-new is the difference between the two published counts
  expect_equal(sum(urps_active_ages("ABU_NET_NEW")$n_active), 279L)
})

test_that("the combined pathway is exactly the sum of its parts", {
  # ABOG_PLUS_ABU is summed on read rather than stored, precisely so this
  # identity cannot be violated by a stale stored total.
  combined <- sum(urps_active_ages("ABOG_PLUS_ABU")$n_active)
  parts <- sum(urps_active_ages("ABOG")$n_active) +
    sum(urps_active_ages("ABU_NET_NEW")$n_active)
  expect_equal(combined, parts)
})

test_that("conus totals the published conus count and is not larger than national", {
  con <- sum(urps_active_ages(geography = "conus")$n_active)
  nat <- sum(urps_active_ages(geography = "national")$n_active)
  expect_equal(con, urps_count(2023L, "board_certified_active", "conus", TRUE))
  expect_equal(con, 1303L)
  expect_lte(con, nat)
})

test_that("the lineage table agrees with the distribution", {
  lin <- urps_lineage()
  cur <- lin[lin$status == "current", , drop = FALSE]
  expect_equal(sum(urps_active_ages(geography = "national")$n_active),
               as.integer(cur$national_active))
  expect_equal(sum(urps_active_ages(geography = "conus")$n_active),
               as.integer(cur$conus_active))
})

test_that("counts form is tidy, sorted, integer, and has no empty ages", {
  a <- urps_active_ages()
  expect_named(a, c("age", "n_active"))
  expect_type(a$age, "integer")
  expect_type(a$n_active, "integer")
  expect_false(is.unsorted(a$age))
  expect_false(anyDuplicated(a$age) > 0)
  expect_true(all(a$n_active > 0))
  expect_true(all(a$age > 0 & a$age < 120))
})

test_that("the vector form expands the counts exactly", {
  a <- urps_active_ages()
  v <- urps_active_ages(as = "vector")
  expect_type(v, "integer")
  expect_equal(length(v), sum(a$n_active))
  expect_equal(as.integer(table(v)[as.character(a$age)]), a$n_active)
  expect_equal(sort(unique(v)), a$age)
})

test_that("pathway and geography are case-insensitive and validated", {
  expect_equal(urps_active_ages("abog"), urps_active_ages("ABOG"))
  expect_equal(urps_active_ages(geography = "NATIONAL"),
               urps_active_ages(geography = "national"))
  expect_error(urps_active_ages("ABOG_ONLY"), "unknown pathway")
  expect_error(urps_active_ages(geography = "state"), "unknown geography")
  expect_error(urps_active_ages(pathway = c("ABOG", "ABU_NET_NEW")), "single string")
  expect_error(urps_active_ages(as = "matrix"))
})

test_that("the distribution is plausible for a certified physician cohort", {
  v <- urps_active_ages(as = "vector")
  expect_gte(min(v), 25L)     # nobody is board-certified as a child
  expect_lte(max(v), 100L)
  expect_gt(stats::median(v), 35)
  expect_lt(stats::median(v), 65)
})
