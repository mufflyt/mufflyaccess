#!/usr/bin/env python3
"""Build the state-level board_certified_active / 2023 extract for ACS/Sheps.

Aggregates the isochrones v2.1.0 provider snapshot (parquet) to STATE-LEVEL
COUNTS only -- no physician-level rows leave the package. Reconstructs the
active-in-2023 rule independently:
    active in 2023 iff certification_year <= 2023 AND
                       (retirement_year is empty OR retirement_year > 2023)

mufflyaccess owns the workforce COUNTS. Population denominators and access
measures are owned by twostep / isochrones and are intentionally left as empty
columns here for the receiving team to join.
"""
import csv
import sys
import pyarrow.parquet as pq

PARQUET = sys.argv[1] if len(sys.argv) > 1 else \
    "tests/testthat/fixtures/isochrones-v2.1.0/urps_provider_snapshot.parquet"
OUT = sys.argv[2] if len(sys.argv) > 2 else \
    "share/acs_sheps/out/urps_state_extract_2023_v2.1.0.csv"
SMALL_CELL = 6  # flag (do not suppress) aggregate counts below this

t = pq.read_table(PARQUET)
cy = t.column("certification_year").to_pylist()
ry = t.column("retirement_year").to_pylist()
st = t.column("state_or_territory").to_pylist()
ic = t.column("is_conus").to_pylist()
bp = t.column("board_pathway").to_pylist()

rows = {}
for c, r, s, g, p in zip(cy, ry, st, ic, bp):
    active = c is not None and c <= 2023 and (r is None or r > 2023)
    if not active:
        continue
    d = rows.setdefault(s, {"combined": 0, "abog": 0, "abu": 0, "is_conus": bool(g)})
    d["combined"] += 1
    if p == "ABOG":
        d["abog"] += 1
    elif p == "ABU_NET_NEW":
        d["abu"] += 1

total = sum(d["combined"] for d in rows.values())
assert total == 1332, f"state extract reconstructs to {total}, expected 1332"

with open(OUT, "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow([
        "state_or_territory", "geography_is_conus", "year", "measure",
        "abog_active", "abu_net_new_active", "combined_active",
        "small_cell_flag", "population_denominator", "providers_per_100k_women",
        "artifact_version", "contract_version", "source_git_commit",
    ])
    for s in sorted(rows):
        d = rows[s]
        w.writerow([
            s, d["is_conus"], 2023, "board_certified_active",
            d["abog"], d["abu"], d["combined"],
            d["combined"] < SMALL_CELL,
            "",  # population_denominator: owned by twostep/isochrones (join key: state)
            "",  # providers_per_100k_women: derived downstream from the denominator
            "2.1.0", "2.1.0", "565755b2a9e2295855edae541db47516c973b27b",
        ])

print(f"wrote {OUT}: {len(rows)} states, {total} providers (board_certified_active/2023)")
