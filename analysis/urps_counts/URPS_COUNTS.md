# URPS counts by year, subspecialty, and urology pathway — reproducible derivation

**What this is.** A traced, board-roster-based count of **URPS** (Urogynecology and
Reconstructive Pelvic Surgery, formerly FPMRS) — and every other ABOG OB/GYN
subspecialty — **by year (2013–2023)**, plus an optional **± urology** (ABOG vs
ABOG + ABU) series, computed deterministically from committed `isochrones`
artifacts. It exists so "how many URPS are there?" has one standard, reproducible
answer instead of an ad-hoc query.

**Golden rule (from `isochrones`):** the count is defined by **board
certification** (ABOG for the OB/GYN pathway, ABU for the urology pathway),
matched to an NPI. **Never by NPPES taxonomy code alone** — taxonomy
self-designation is incomplete (~51% of certified FPMRS carry `207VF0040X` in any
NPPES slot) and would badly undercount.

> This lives in `mufflyaccess/analysis/` as derived analysis output. It is **not**
> part of the R package (build-ignored). The authoritative provider data stays in
> `isochrones`; this folder holds the standard method + the derived CSVs + their
> provenance.

---

## 1. Source (committed, dated, hashable)

| | |
|---|---|
| **ABOG file** | `isochrones/manuscript/tables/table1_physician_characteristics.csv` |
| **SHA-256** | `5f1b6167fad81ba896c0b1bc1ceda8eb966e681f51b176105b389a27399e0c0f` |
| **Rows** | 7,208 (one per ABOG certificate; 7,208 distinct NPIs — no dual-subspecialty double counting) |
| **Cohort** | ABOG-certified OB/GYN subspecialists, NPI-matched, **2023 active-workforce snapshot** (`analysis_year = 2023`) |
| **ABU file** (optional, for ± urology) | `isochrones/data/abu_urology/abu_fpmrs_net_new_geocoded_*.csv` — **gitignored**; urology-pathway URPS net-new to ABOG |

`provenance.json` records the SHA-256 of every input actually used. Cite the hash
with the number: a different snapshot → a different hash → knowingly a different
number.

## 2. The active-in-year rule

Mirrors `isochrones/R/filter_active_providers_for_date.R` (the project's 7-source
retirement policy) using the columns committed in `table1`:

> Active in year *Y* iff `certification_year <= Y` **AND** (`retirement_year`
> empty **OR** `retirement_year > Y`).

`retirement_year` is the 7-source consensus exit (ABMS lapse, NPI deactivation,
state licensure, Open Payments, hospital affiliations, Medicare Part B, Part D);
for the 2023 base snapshot it equals `is_retired_for_cohorting`.

**Validation anchors (both reproduced exactly):** total active 2023 = **5,336** ✓;
URPS active 2023 = **1,031** ✓ (the known ABOG active-workforce figure).

## 3. Outputs

### `urps_by_year_subspecialty.csv` — all ABOG subspecialties by year
Long form: `year, subspecialty, abbrev, n_active, n_ever_certified_by_year,
n_retired_by_year`. Pivot of `n_active`:

| abbrev | 2013 | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 | 2022 | 2023 |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| MFM  | 1813 | 1922 | 2032 | 2098 | 2173 | 2217 | 2218 | 2171 | 2089 | 1959 | 1529 |
| REI  | 1001 | 1054 | 1101 | 1132 | 1150 | 1158 | 1096 | 1074 | 1043 |  984 |  759 |
| GO   |  815 |  882 |  938 |  973 | 1028 | 1058 | 1093 | 1091 | 1118 | 1104 | 1052 |
| **URPS** | **843** | **905** | **954** | **987** | **1036** | **1060** | **1089** | **1092** | **1092** | **1079** | **1031** |
| MIGS |  354 |  395 |  430 |  481 |  511 |  547 |  583 |  594 |  628 |  631 |  605 |
| CFP  |   86 |  100 |  120 |  136 |  147 |  162 |  178 |  184 |  215 |  216 |  185 |
| PAG  |  127 |  139 |  152 |  166 |  177 |  189 |  194 |  191 |  200 |  194 |  175 |
| **total** | 5039 | 5397 | 5727 | 5973 | 6222 | 6391 | 6451 | 6397 | 6385 | 6167 | **5336** |

The URPS row is the **"without urology"** (ABOG / OB-GYN pathway) series.

### `urps_by_year_pathway.csv` — URPS ± urology
Long form: `year, pathway {ABOG | ABU | ABOG+ABU}, urology {without | urology_pathway | with}, n_active_urps`.
Without an ABU roster the file holds only the ABOG (`without`) rows — the fully
reproducible layer. Supply `--abu` to add the ABU and combined rows.

### Query: active vs ever-certified — `subspecialist_counts.R`

A repo-local deriving accessor (base R, fail-loud, no hardcoded integers) that
reads `urps_by_year_subspecialty.csv` and returns both measures per subspecialty
× year:

- **`n_active`** — physicians in the workforce that year (certified by *Y* and
  not retired by *Y*).
- **`n_ever_certified`** — cumulative ABOG certifications with cert year ≤ *Y*.
  At the final snapshot year this equals the all-time cohort size.
- plus `n_retired` and `pct_active = 100 * active / ever_certified`.

```r
source("subspecialist_counts.R")

subspecialist_counts("GO", 2023)
#>   year        subspecialty abbrev n_active n_ever_certified n_retired pct_active
#> 1 2023 Gynecologic Oncology     GO     1052             1190       138       88.4

n_active("GO", 2023)          # 1052   (active workforce)
n_ever_certified("GO", 2023)  # 1190   (all ever certified)

subspecialist_counts("URPS")  # every year for URPS
subspecialist_counts(year = 2023)  # all 7 subspecialties, 2023
```

CLI: `Rscript subspecialist_counts.R GO 2023`. The accessor fails loudly if the
CSV is missing, so a returned number always traces to the current committed
source (`provenance.json`).

## 4. "With vs without urology" — the ABU pathway

URPS is certified by two boards; `table1` is **ABOG only**. The **ABU** roster is
net-new to ABOG (already deduped by NPI), so the union is a simple sum. The
committed ABU **map roster carries no year columns**, so the generator adds ABU in
one of two modes:

- **snapshot** (no year columns): ABU is a **constant level shift** across all
  years (`abu.temporal = false` in provenance). The *shape* of the with-urology
  series over time is driven by ABOG; ABU raises the level.
- **temporal** (roster has `certification_year` / `retirement_year`): the same
  active-in-year rule is applied to ABU → a true ABU time series.

| URPS cohort (2023 anchor) | Count | Source |
|---|--:|---|
| **Without urology** (ABOG active) | **1,031** | this folder / `table1` (computed) |
| ABU (urology-pathway) active | +308 | ABU roster — reported; recomputed here once the roster is supplied |
| **With urology** (ABOG + ABU) | **1,339** | sum of the two rows |

> **Frozen headline counterpart.** The `mufflyaccess` package also *exports*
> frozen headline constants for this — `URPS_COUNT_ABOG_ONLY_2025` (1031, without
> urology) and `URPS_COUNT_ABOG_PLUS_ABU_2025` (1295, with urology; +264 ABU
> net-new) in `R/urps_workforce.R`. Those are the stable single numbers for
> downstream code; this folder is the reproducible by-year/by-subspecialty
> pipeline behind them. They agree on the ABOG active figure (1031).

**Do not conflate cohorts.** Three legitimate URPS numbers, each for a different
question:

| Cohort | URPS | Urology? | Committed source |
|---|--:|---|---|
| Provider **density** (ABOG FPMRS w/ NPI) | 1,172 | without | `manuscript/stats/table2_provider_density.csv` |
| Access-**map roster** | 1,652 (1,380 ABOG + 272 ABU) | with | `vignettes/urogyn_app/data/points.geojson` (built by `scripts/export_urogyn_map_data.R`) |
| Active **workforce** 2023 | 1,339 (1,031 ABOG + 308 ABU) | with | `table1` (ABOG) + ABU roster |

## 5. Caveats (read before citing)

- **Retirement-detection window.** `retirement_year` populates from ~2016 on. The
  2023-anchored cohort under-represents physicians who exited before 2016, so
  **2013–2015 are approximate**; **2016–2023 are firm**.
- **Board pathway.** ABOG only unless `--abu` is supplied.
- **Entry = certification year.** The `practice_start = cert − 1` refinement from
  `R/create_yearly_active_providers_subspecialty_aware.R` is not applied;
  `certification_year` is the objective, complete field in `table1`. Applying the
  −1 offset shifts each series left by one year.
- **This is the `table1` cohort**, distinct from the density and map-roster
  cohorts (§4) — same subspecialty, different filters.

## 6. Regenerate

```sh
# ABOG series (from the isochrones repo, or point at the file directly):
python3 count_urps.py /path/to/isochrones/manuscript/tables/table1_physician_characteristics.csv \
        --outdir .

# with the ± urology (ABU) layer:
python3 count_urps.py .../table1_physician_characteristics.csv \
        --abu /path/to/isochrones/data/abu_urology/abu_fpmrs_net_new_geocoded_2026-07-14.csv \
        --outdir .

# national anchors to 1031 (URPS 2023); add --conus to exclude AK/HI/territories
```

Pure Python stdlib — no dependencies. Same inputs → identical CSVs and hashes,
every run.

### Self-test (no real data needed)
```sh
# snapshot ABU (level shift):  URPS 2023 with urology = 1031 + 3 = 1034 (national)
python3 count_urps.py .../table1_physician_characteristics.csv --abu testdata/abu_snapshot.csv --outdir /tmp
# temporal ABU (true series):  ABU 2019 = 3, 2021 = 2
python3 count_urps.py .../table1_physician_characteristics.csv --abu testdata/abu_temporal.csv --outdir /tmp
```
