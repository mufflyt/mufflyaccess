# Charter — the URPS workforce SSOT producer provenance

**Status:** the served contract is **v3.0.0** (canonical 2023 national
`board_certified_active` = **1306**; CONUS **1303**). This charter records how those
numbers are produced, what is and is not committed, and the remediation still open.
It is the remediation home named in the artifact manifest
(`known_limitations` → "Primary remediation (docs/CHARTER_URPS_SSOT.md)").

See `../ARCHITECTURE.md` for the one-directional layer model
(isochrones → mufflyaccess → cliff / twostep / apps). This charter is the
provenance detail behind the top box of that diagram.

## The v3.0.0 provenance chain

```
enriched source rosters (physician-level, hashed)
  cliff/data/abog_all_urps_ENRICHED_2026-07-22.csv   sha256 96a9be0b…
  cliff/data/abu_all_urps_ENRICHED_2026-07-22.csv    sha256 5ad39628…
  data/abog_pipeline/canonical_abog_npi_LATEST.rds   sha256 d8436ef2…
        │  combined_source_sha256 a6aad44a…
        ▼
producer (isochrones)  → source commit 74085a9e695eec5350275a29d8655512ad57422b
        │                 artifact commit cf7222df2dba8a75831b372b7787af379a9b799d
        ▼
artifacts/workforce/  (immutable, hashed)
  urps_counts_by_year.csv        measure × geography × board_pathway, 2013–2023 + 2025
  urps_provider_snapshot.parquet 1 row / NPI (rows_national 1339, rows_active_2023 1306)
  urps_manifest.json             sources, defs, dedup, hashes, git SHA, limitations
  urps_release_contract.json     contract_version 3.0.0, canonical cell 1306
        ▼
mufflyaccess  validates (hash + schema) and serves — never re-derives
```

The authoritative copy of every hash above is the served manifest
(`inst/extdata/urps_manifest.json`); this charter references it, it does not restate it.
mufflyaccess verifies the served bytes against it at read time
(`urps_provenance(detailed = TRUE)$detail$integrity`).

**Cohort / cert basis (why 1306, not the retired 1332).** v3.0.0 keys
`board_certified_active` on the **URPS subspecialty** certification year
(training-accurate, post-fellowship): ABOG `sub1startdate` where present, else a
fellowship proxy (primary + 3 yr OB-GYN / + 2 yr urology). v2.1.0 keyed on the
**primary** board-cert year and produced 1332 / 1329; those are **RETIRED** cells,
surfaced only by `urps_lineage()` / `urps_retired_values()` and never presented as
current.

## What is committed, what is not

| Component | Location | State |
|---|---|---|
| Served v3.0.0 artifact bytes | `inst/extdata/` (bundled bootstrap) + isochrones `artifacts/workforce/` @ `cf7222df` | ✅ committed / released |
| Enriched source rosters (inputs) | `cliff/data/{abog,abu}_all_urps*_2026-07-22.csv` | ✅ now git-tracked in cliff (the manifest's "UNTRACKED" note is **stale**) |
| **v3.0.0 producer script** | — | ❌ **not committed in its owning repo (isochrones)** |
| Legacy producer reference | `handoff/isochrones/build_urps_workforce_artifacts.R` | ⚠️ **STALE v1.0.0** — do not use (see below) |

### The open gap: no committed v3.0.0 producer

The script that transforms the enriched rosters into the v3.0.0 `measure × geography`
artifact — the one applying the `urps_subspecialty_cert_year` basis, the
`roster_snapshot` measure, and the geography-resolution rule — is **not committed**
in isochrones. It cannot be reconstructed here from the served bytes, because a
reconstruction that did not reproduce the SHA-pinned outputs would silently diverge
from the contract. Committing it is isochrones' responsibility.

**Do not use `handoff/isochrones/build_urps_workforce_artifacts.R` to regenerate the
contract.** It is a superseded **v1.0.0** producer: it emits `contract_version 1.0.0`
on the old **fused-geography** schema (no `measure` / `geography` columns), keys on
`certification_year` (the primary-cert basis → the **retired 1332**), and reads a
different input than the v3.0.0 manifest names. Running it would regenerate
retired-basis numbers on an obsolete schema.

### PII posture

The enriched rosters tracked in cliff carry physician-level columns (`npi`, `name`).
Only **aggregate** counts leave the SSOT boundary (mufflyaccess serves counts +
provenance; the ACS/Sheps share package emits aggregates only). The physician-level
inputs remaining tracked in cliff is a governance decision owned by that repo, noted
here for provenance completeness.

## Remediation checklist

- [ ] **isochrones:** commit the real v3.0.0 producer (subspecialty-cert basis,
      `measure × geography` schema, `roster_snapshot`, geography resolution) at/under
      the `74085a9e6` source lineage, so the contract can be re-derived and verified
      against the pinned hashes.
- [ ] **isochrones:** on the next release, correct the manifest `known_limitations`
      note that still calls the base rosters "UNTRACKED with NO committed producer" —
      the inputs are now tracked in cliff.
- [x] **mufflyaccess:** purge retired-cell (1332 / 1329) framing from the handoff
      material and mark the legacy producer stale (this change).
- [x] **cliff:** the SSOT-boundary docstring in `R/urps_baseline.R` no longer
      documents 1332 / 1329 as the canonical baseline (Phase 0).
- [x] **cliff / twostep:** the mufflyaccess pin is reconciled to `@69a8560`
      (contract v3.0.0) across DESCRIPTION, `renv.lock`, and install-text (Phase 0).
