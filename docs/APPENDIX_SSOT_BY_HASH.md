# Appendix — large analysis inputs served by hash, never by path

**Status:** shipped in `mufflyaccess` 0.12.0. Covers the two large, unbundled
analysis inputs the package now gates by SHA-256: the **frozen isochrone set**
(`R/ssot_frozen_isochrones.R`) and the **ABOG certification-registry refresh**
(`R/ssot_abog_refresh.R`). See `../ARCHITECTURE.md` for the one-directional layer
model (isochrones → mufflyaccess → cliff / twostep / apps); this appendix is the
provenance detail behind those two inputs.

## Why a path is not enough

Most SSOT values in this package are small constants shipped inside the package.
Two inputs are not: a **1.4 GB** consolidated isochrone set and a **9 MB** ABOG
registry CSV. Both are too large to bundle usefully and small enough that a stale
or wrong copy is easy to acquire — and, crucially, **the wrong copy is
indistinguishable from the right one by name, path, or file size.**

The concrete incident this guards against: the E2SFCA primary analysis was
computed against **one** isochrone set. At least three near-identical sets exist
on the author's machines with the same file names, the same four bands, and
similar sizes. The wrong one has **3,909 origins** against the right one's
**4,050**; the 141 it lacks include **44 physician locations**. Used unknowingly
it does not error — it silently drops those providers' supply and **deflates
access by up to 3.7%**. Only the hash tells the two apart.

## The discipline

1. **The checksum ships; the payload does not.** The package bundles only
   `inst/extdata/ssot/frozen_isochrones.sha256`,
   `inst/extdata/ssot/abog_refresh.sha256`, and
   `inst/extdata/ssot/ssot_sources.json`. The 1.4 GB / 9 MB payloads live in the
   canonical stores below and are fetched out of band.
2. **Every accessor verifies by hash and fails closed.** A directory or file the
   package has not hashed against the manifest is never returned. There is no
   "trust the path" mode.
3. **A hash match with a missing column is a schema change, not a wrong file.**
   `read_abog_refresh()` verifies the hash first, then checks the columns, and
   says which of the two failed — so a genuine upstream schema change is never
   misreported as "you have the wrong file."

## Frozen isochrone set

- **Canonical run:** `e2sfca_20260712_190734`
- **Origins:** 4,050 · **Bands:** 30 / 60 / 120 / 180 minutes (four consolidated
  files, one per band)
- **Manifest:** `inst/extdata/ssot/frozen_isochrones.sha256` (per-band SHA-256)
- **Canonical copies** (in `ssot_sources.json`):
  - S3: `s3://tmuffly-isochrone-library-163531628641/frozen/e2sfca_20260712_190734/`
  - Dropbox: `MufflyAccess_SSOT/frozen_isochrones/e2sfca_20260712_190734/`

**Resolution order** (`frozen_isochrones_dir()`): `use_frozen_isochrones("<dir>")`
→ option `mufflyaccess.frozen_isochrones_dir` → env
`MUFFLYACCESS_FROZEN_ISOCHRONES_DIR` → env `E2SFCA_ISO_DIR` (compatibility). Each
candidate is re-hashed (unless `verify = FALSE`) and the first verified one wins;
if none verifies, the error names every candidate tried.

| Function | Purpose |
|---|---|
| `verify_frozen_isochrones(dir, quiet = FALSE)` | Hash every band vs the manifest; error names the bands that differ or are absent. |
| `use_frozen_isochrones(dir)` | Verify **then** adopt for the session. |
| `frozen_isochrones_dir(verify = TRUE)` | Return the verified directory, or a loud error with fetch instructions. |
| `frozen_isochrones_provenance()` | Checksums, resolved dir, `verified` flag, and the canonical copies. |

## ABOG certification-registry refresh

- **File:** `refresh_merged.csv` · **Rows:** 79,398 · **Size:** ~9 MB
- **SHA-256:** `6e32189a5f2e404af5d7a9bc920c5e962d3a4db1052a7fbcfae5585506501fbd`
- **Required columns:** `userid, name, startDate, certStatus, mocStatus, city,
  state, ID, ScrapedAt, refresh_source`
- **Canonical copies** (in `ssot_sources.json`):
  - S3: `s3://tmuffly-isochrone-library-163531628641/abog_refresh_2026/refresh_merged.csv`
  - Dropbox: `MufflyAccess_SSOT/abog_refresh_2026/refresh_merged.csv`

**Resolution order** (`abog_refresh_path()`): `use_abog_refresh("<path>")` →
option `mufflyaccess.abog_refresh_path` → env `MUFFLYACCESS_ABOG_REFRESH`.

| Function | Purpose |
|---|---|
| `verify_abog_refresh(path)` | Hash `refresh_merged.csv` vs the pinned SHA-256; error shows both hashes. |
| `use_abog_refresh(path)` | Verify **then** adopt for the session. |
| `abog_refresh_path(verify = TRUE)` | Return the verified path, or a loud error with fetch instructions. |
| `read_abog_refresh(path = NULL)` | Verify, then read; a hash match with a missing column is reported as a schema change. |
| `abog_refresh_provenance()` | Expected SHA-256, resolved path, `verified` flag, and the canonical copies. |

## Typical use

```r
library(mufflyaccess)

# 1. Fetch the payload out of band (see the provenance functions for the exact
#    S3 / Dropbox locations); the package never downloads it for you.
frozen_isochrones_provenance()$s3   # canonical S3 URI for the isochrone set
abog_refresh_provenance()$s3        # canonical S3 URI for refresh_merged.csv

# 2. Adopt the copy you fetched — verification happens here and fails closed.
use_frozen_isochrones("~/data/e2sfca_20260712_190734")
use_abog_refresh("~/data/abog_refresh_2026/refresh_merged.csv")

# 3. Use it. Every read re-checks the hash unless you pass verify = FALSE.
dir <- frozen_isochrones_dir()      # verified path, or a loud error
abog <- read_abog_refresh()         # 79,398 rows, hash-checked
```

Non-interactive configuration (CI, batch jobs) sets the option or environment
variable instead of calling `use_*()`; resolution and verification are identical.

## What ships in the package, and what does not

| Artifact | Bundled? | Location |
|---|---|---|
| Per-band isochrone checksums | yes | `inst/extdata/ssot/frozen_isochrones.sha256` |
| ABOG refresh checksum | yes | `inst/extdata/ssot/abog_refresh.sha256` |
| Canonical-source registry | yes | `inst/extdata/ssot/ssot_sources.json` |
| 1.4 GB isochrone payload | **no** | S3 / Dropbox (fetched out of band) |
| 9 MB `refresh_merged.csv` payload | **no** | S3 / Dropbox (fetched out of band) |

The nine exports (`verify_frozen_isochrones`, `use_frozen_isochrones`,
`frozen_isochrones_dir`, `frozen_isochrones_provenance`, `verify_abog_refresh`,
`use_abog_refresh`, `abog_refresh_path`, `read_abog_refresh`,
`abog_refresh_provenance`) are recorded in the pinned cross-repo API contract at
`tests/testthat/api-surface.txt`.
