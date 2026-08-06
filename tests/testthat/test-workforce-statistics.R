# Workforce inferential statistics (R/workforce_statistics.R).
#
# These arrived from simulation, which had the strongest of three divergent
# copies. The dplyr pipelines were rewritten in base R to keep mufflyaccess
# free of tidyverse dependencies, so the first job of these tests is to prove
# the rewrite did not change any answer.

test_that("the Wilson interval brackets the point estimate and stays in [0,1]", {
  r <- calculate_proportion_ci(12, 40)
  expect_equal(r$proportion, 0.3)
  expect_lt(r$lower_ci, 0.3)
  expect_gt(r$upper_ci, 0.3)
  expect_gte(r$lower_ci, 0)
  expect_lte(r$upper_ci, 1)
  expect_identical(r$method, "Wilson")

  # The reason Wilson is used rather than Wald: at x == n the Wald interval has
  # zero width and sits on the boundary, which is exactly where these are read.
  edge <- calculate_proportion_ci(40, 40)
  expect_lt(edge$lower_ci, 1)
  expect_lte(edge$upper_ci, 1)
})

test_that("a zero denominator returns NA rather than NaN", {
  r <- calculate_proportion_ci(0, 0)
  expect_true(is.na(r$proportion))
  expect_identical(r$note, "Zero denominator")
})

test_that("small samples are refused in the RESULT, not just warned about", {
  # A warning can be ignored and a p-value still read. Here there is no p-value
  # to read, which is the point.
  r <- calculate_two_prop_test(2, 5, 3, 6)
  expect_identical(r$method, "descriptive_only")
  expect_true(is.na(r$p_value))
  expect_false(r$significant)
  expect_match(r$note, "too small")

  expect_identical(calculate_two_prop_test(12, 40, 20, 60)$method, "prop.test")
})

test_that("rural-metro bundles rate, interval and test together", {
  r <- calculate_rural_metro_comparison(30, 100, 40, 200)
  expect_equal(r$rural$rate_pct, 30)
  expect_equal(r$metro$rate_pct, 20)
  expect_equal(r$comparison$rate_difference_pct, 10)
  expect_lt(r$rural$ci_lower, 30)
  expect_gt(r$rural$ci_upper, 30)

  # A zero denominator must not become a 0% rate: absent is not zero.
  z <- calculate_rural_metro_comparison(0, 0, 40, 200)
  expect_true(is.na(z$rural$rate_pct))
  expect_true(is.na(z$comparison$rate_difference_pct))
})

test_that("horizon_years is honoured, not hardcoded to 5", {
  # The bug this guards: cliff and isochrones multiply by a literal 5 beside a
  # comment explaining that 5 IS the horizon, so moving the horizon left the
  # arithmetic behind.
  ret  <- data.frame(subspecialty = c("FPMRS", "GO"), retiring_count = c(50, 30))
  grad <- data.frame(subspecialty = c("FPMRS", "FPMRS", "GO"), graduates = c(10, 12, 4))

  five <- calculate_replacement_gap(ret, grad)
  ten  <- calculate_replacement_gap(ret, grad, horizon_years = 10)
  expect_equal(ten$overall$total_graduates_projected,
               2 * five$overall$total_graduates_projected)
  expect_equal(five$overall$horizon_years, 5)
  expect_equal(ten$overall$horizon_years, 10)
})

test_that("a subspecialty with no graduates contributes zero, not NA", {
  ret  <- data.frame(subspecialty = c("FPMRS", "GO"), retiring_count = c(50, 30))
  grad <- data.frame(subspecialty = "FPMRS", graduates = 10)
  r <- calculate_replacement_gap(ret, grad)
  go <- r$by_subspecialty[r$by_subspecialty$subspecialty == "GO", ]
  expect_equal(go$annual_grads, 0)
  expect_equal(go$projected_grads, 0)
  expect_equal(go$net_gap, 30)
  expect_false(go$adequate_replacement)
})

test_that("zero retirements give NA, not Inf", {
  # Inf propagates into every downstream mean and plot axis; NA announces itself.
  ret  <- data.frame(subspecialty = "FPMRS", retiring_count = 0)
  grad <- data.frame(subspecialty = "FPMRS", graduates = 10)
  r <- calculate_replacement_gap(ret, grad)
  expect_true(is.na(r$by_subspecialty$replacement_ratio))
  expect_false(is.infinite(r$by_subspecialty$replacement_ratio))
})

test_that("replacement gap validates its inputs and its horizon", {
  ret  <- data.frame(subspecialty = "FPMRS", retiring_count = 50)
  grad <- data.frame(subspecialty = "FPMRS", graduates = 10)
  expect_error(calculate_replacement_gap(data.frame(a = 1), grad), "retirees_by_subspec")
  expect_error(calculate_replacement_gap(ret, data.frame(a = 1)), "fellowship_grads")
  expect_error(calculate_replacement_gap(ret, grad, horizon_years = -1), "horizon_years")
})

test_that("output row order is deterministic", {
  # Two callers with the same data in different row order must get the same
  # table, or a diff of two reports shows spurious changes.
  a <- data.frame(subspecialty = c("GO", "FPMRS"), retiring_count = c(30, 50))
  b <- data.frame(subspecialty = c("FPMRS", "GO"), retiring_count = c(50, 30))
  grad <- data.frame(subspecialty = c("FPMRS", "GO"), graduates = c(10, 4))
  expect_equal(calculate_replacement_gap(a, grad)$by_subspecialty,
               calculate_replacement_gap(b, grad)$by_subspecialty)
})

test_that("state vulnerability ranks by pct_loss and reports the weighted score", {
  d <- data.frame(
    state = c("AA", "BB", "CC"),
    count_active = c(1000, 10, 500),
    count_at_risk = c(100, 5, 100),
    pct_loss_if_retire = c(10, 50, 20),
    zero_coverage_if_retire = c(FALSE, TRUE, FALSE))
  r <- calculate_state_vulnerability(d, top_n = 2)

  expect_equal(nrow(r), 2L)
  expect_equal(r$state, c("BB", "CC"))          # ordered by pct_loss, as documented
  expect_true("vulnerability_score" %in% names(r))
  # Score weights by log10(active): AA's 10% over 1000 outscores BB's 50% over 10.
  full <- calculate_state_vulnerability(d, top_n = 3)
  expect_gt(full$vulnerability_score[full$state == "CC"],
            full$vulnerability_score[full$state == "BB"])
})

test_that("state vulnerability drops NA loss rather than ranking it", {
  d <- data.frame(state = c("AA", "BB"), count_active = c(100, 100),
                  count_at_risk = c(10, 10), pct_loss_if_retire = c(NA, 20),
                  zero_coverage_if_retire = c(FALSE, FALSE))
  r <- calculate_state_vulnerability(d)
  expect_equal(r$state, "BB")
})
