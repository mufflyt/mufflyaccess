# Contributing to mufflyaccess

`mufflyaccess` is a **single source of truth**. Its whole value is that a shared
constant is defined exactly once, carries its provenance, and fails loudly if it
is ever edited into an impossible state. Changes are therefore deliberate and
reviewed — a bump here can move a published number in `isochrones`, `twostep`, or
`cliff`.

Please read [`docs/CROSS_REPO_USAGE.md`](docs/CROSS_REPO_USAGE.md) first: it shows
which repo consumes which export, i.e. what your change can break.

## Does this value belong here?

Add a value only if the projects must **agree** on it. If a value is genuinely
repo-specific it stays in that repo — even when it looks similar to something
here. The canonical example: the 65+ access denominator is Wu-2014
(`WU2014_PFD_PREVALENCE`, in this package), while `cliff`'s workforce supply/
demand line uses a full-age **Nygaard-2008** curve — a different cohort and
source that deliberately stays in `cliff`. Similar name, different truth: keep
them apart.

## The promotion checklist

When you promote a constant or function into the package, do all of these **in
the same PR**:

1. **Add the object in `R/`** with a roxygen block. Prefer promoting *verbatim*
   from the origin repo so behavior is byte-for-byte preserved.
2. **Cite the primary source.** The `@source` tag must name the authoritative
   original — the Census table, USDA data product, or peer-reviewed paper (with a
   URL, DOI, or PMID) — not only the internal repo path it came from. Attach
   provenance attributes (`vintage`, `table`, `source`, …) where a consumer reads
   them.
3. **Add a fail-loud `stopifnot()` block** in the same file that validates the
   value at namespace load: type, length, range, and any cross-value invariant
   (e.g. a derived form must equal its base). An impossible edit must break
   `library(mufflyaccess)` immediately.
4. **Derive, don't duplicate.** If two representations must agree, compute one
   from the other (as `PRIMARY_ACCESS_BAND_SEC` is from `_MIN`, and
   `CONUS_STATE_ABBR` from `CONUS_STATE_FIPS`) so they cannot drift.
5. **Add a test** under `tests/testthat/` asserting the published value and its
   invariants.
6. **Regenerate `NAMESPACE`** — do **not** hand-edit it. Run
   `devtools::document()`; roxygen writes `NAMESPACE` from the `@export` tags.
7. **Record the change in [`NEWS.md`](NEWS.md)** and bump `Version` in
   `DESCRIPTION`.
8. **Update the usage map.** Re-run `tools/usage_matrix.sh ../isochrones
   ../twostep ../cliff` and fold changes into `docs/CROSS_REPO_USAGE.md`.

## Adopting the SSOT in a consumer repo (the shim pattern)

Consumers replace their local copy with a thin **shim** so drift becomes
impossible:

```r
# R/<thing>.R in the consumer repo -- SSOT SHIM
if (!requireNamespace("mufflyaccess", quietly = TRUE))
  stop('Package "mufflyaccess" is required. Install: renv::install("mufflyt/mufflyaccess").',
       call. = FALSE)
suppressPackageStartupMessages(library(mufflyaccess))   # attaches the promoted symbols
```

Add a `tests/testthat/test-mufflyaccess-consistency.R` that asserts the promoted
symbols resolve to the package namespace
(`environmentName(environment(get(fn))) == "mufflyaccess"`) and that the boundary
contracts are frozen — see the existing consistency tests in `twostep` and
`cliff` for the shape.

## Local checks before opening a PR

```r
devtools::document()   # regenerate NAMESPACE + man/ from roxygen
devtools::test()       # testthat 3e
devtools::check()      # R CMD check — must be clean
```

Pin consumers to a **tagged** release (`renv::install("mufflyt/mufflyaccess@vX.Y.Z")`),
never the branch: reproducibility is the point.
