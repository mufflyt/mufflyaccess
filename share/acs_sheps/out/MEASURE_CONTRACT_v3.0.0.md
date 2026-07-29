# URPS workforce -- measurement contract (for ACS / Sheps)

_Generated from the isochrones contract v3.0.0 artifact. Do not hand-edit._

**Canonical 2023 board-certified active count: national 1,306 / CONUS 1,303** (URPS
subspecialty-cert basis). 1,339 is the 2025 roster snapshot, not the 2023 active
count. **1,332 / 1,329 are RETIRED v2.1.0 cells (primary-cert basis) and must
never be presented as current.**

## Canonical call
```r
mufflyaccess::urps_count(year = 2023, measure = "board_certified_active",
                         geography = "national", include_urology = TRUE,
                         incomplete = "error", details = TRUE)   # 1,306
```

## Headline cells (contract v3.0.0)

| measure / geography | ABOG | ABU net-new | combined |
|---|---|---|---|
| board_certified_active / national / 2023 | 1027 | 279 | **1306** |
| board_certified_active / conus / 2023 | 1026 | 277 | **1303** |
| roster_snapshot / national / 2025 | 1031 | 308 | **1339** |
| roster_snapshot / conus / 2025 | 1030 | 306 | **1336** |

## Contract lineage

| Contract | National active | CONUS active | Status | Basis |
|---|---|---|---|---|
| 3.0.0 | 1306 | 1303 | current | URPS subspecialty cert year |
| 2.1.0 | 1332 | 1329 | retired | primary board cert year |

**Why 3.0.0 changed:** v2.1.0 counted active on the *primary* board-cert year
(national 1,332). v3.0.0 keys on the *URPS subspecialty* cert year (training-
accurate, post-fellowship); 33 providers whose subspecialty cert postdates 2023
are correctly excluded, giving 1,306. The 2025 roster snapshot (1,339) is unchanged.

## Source

Publicly accessible ABOG physician-certification information, integrated with
other public physician-practice sources and independently reconciled for
workforce research. ABOG did not supply, license, or endorse this derived
dataset.

mufflyaccess owns the workforce counts + provenance. Population denominators and
spatial access measures are owned by twostep / isochrones (see the join spec).
