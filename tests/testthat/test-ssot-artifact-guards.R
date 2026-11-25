# Coverage for the hash-gated SSOT artifact machinery (ssot_abog_refresh.R,
# ssot_frozen_isochrones.R, zzz.R). The canonical payloads are not distributed
# with this public package, but every failure path -- missing configuration,
# wrong file, wrong hash, absent band -- is testable without them, and those
# paths are where the safety logic lives.

library(testthat)

# ── verify_abog_refresh ───────────────────────────────────────────────────────

test_that("verify_abog_refresh errors on a missing file", {
  expect_error(verify_abog_refresh("/nonexistent/refresh_merged.csv"), "file not found")
})

test_that("verify_abog_refresh rejects a file whose hash differs", {
  f <- tempfile(fileext = ".csv")
  writeLines("userid,name\n1,smith", f)
  expect_error(verify_abog_refresh(f), "not the canonical ABOG registry refresh")
})

# ── abog_refresh_path resolution order ───────────────────────────────────────

test_that("abog_refresh_path errors when nothing is configured", {
  withr::local_options(mufflyaccess.abog_refresh_path = NULL)
  withr::local_envvar(MUFFLYACCESS_ABOG_REFRESH = "")
  expect_error(abog_refresh_path(), "no ABOG registry refresh configured")
})

test_that("abog_refresh_path errors when configured paths fail verification", {
  f <- tempfile(fileext = ".csv")
  writeLines("not the canonical file", f)
  withr::local_options(mufflyaccess.abog_refresh_path = f)
  withr::local_envvar(MUFFLYACCESS_ABOG_REFRESH = "")
  expect_error(abog_refresh_path(), "none of the configured paths")
})

test_that("read_abog_refresh verifies the hash before reading", {
  f <- tempfile(fileext = ".csv")
  writeLines("userid,name\n1,smith", f)
  expect_error(read_abog_refresh(f), "not the canonical")
})

test_that("abog_refresh_provenance reports unverified when nothing resolves", {
  withr::local_options(mufflyaccess.abog_refresh_path = NULL)
  withr::local_envvar(MUFFLYACCESS_ABOG_REFRESH = "")
  prov <- abog_refresh_provenance()
  expect_type(prov, "list")
  expect_true(is.character(prov$sha256))
  expect_false(isTRUE(prov$verified))
})

# ── frozen isochrones ─────────────────────────────────────────────────────────

test_that("verify_frozen_isochrones errors on a non-directory", {
  expect_error(verify_frozen_isochrones(NULL), "not a directory")
  expect_error(verify_frozen_isochrones("/nonexistent/dir"), "not a directory")
})

test_that("verify_frozen_isochrones reports absent bands in an empty dir", {
  d <- tempfile()
  dir.create(d)
  expect_error(verify_frozen_isochrones(d, quiet = TRUE), "NOT the frozen isochrone set")
  expect_error(verify_frozen_isochrones(d, quiet = TRUE), "absent")
})

test_that("verify_frozen_isochrones reports hash mismatches for wrong content", {
  d <- tempfile()
  dir.create(d)
  # Fabricate files under the manifest's band names with wrong content.
  manifest <- mufflyaccess:::.frozen_iso_manifest()
  for (nm in names(manifest)) writeLines("wrong content", file.path(d, nm))
  expect_error(verify_frozen_isochrones(d, quiet = TRUE), "hash differs")
})

test_that("frozen_isochrones_dir errors when nothing is configured", {
  withr::local_options(mufflyaccess.frozen_isochrones_dir = NULL)
  withr::local_envvar(MUFFLYACCESS_FROZEN_ISOCHRONES_DIR = "", E2SFCA_ISO_DIR = "")
  # a locally-adopted directory from another test must not leak in
  if (exists("dir", envir = mufflyaccess:::.frozen_iso_env)) {
    rm("dir", envir = mufflyaccess:::.frozen_iso_env)
  }
  expect_error(frozen_isochrones_dir(), "no frozen isochrone directory configured")
})

test_that("frozen_isochrones_dir errors when configured dirs fail verification", {
  d <- tempfile()
  dir.create(d)
  withr::local_options(mufflyaccess.frozen_isochrones_dir = d)
  withr::local_envvar(MUFFLYACCESS_FROZEN_ISOCHRONES_DIR = "", E2SFCA_ISO_DIR = "")
  expect_error(frozen_isochrones_dir(), "none of the configured directories")
})

test_that("frozen_isochrones_provenance reports structure", {
  prov <- frozen_isochrones_provenance()
  expect_type(prov, "list")
  expect_true(is.character(prov$checksums) || is.null(prov$checksums))
})

# ── zzz.R deprecated active bindings ─────────────────────────────────────────

test_that("deprecated URPS count constants warn on genuine access but still return values", {
  expect_warning(v <- URPS_COUNT_ABOG_ONLY_2025, "deprecat")
  expect_equal(v, 1031L)
  expect_warning(v2 <- URPS_COUNT_ABOG_PLUS_ABU_2025, "deprecat")
  expect_equal(v2, 1339L)
})
