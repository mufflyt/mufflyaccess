#!/usr/bin/env python3
"""Build the state-level board_certified_active / 2023 extract for ACS/Sheps.

Aggregates the isochrones v3.0.0 provider snapshot (parquet) to STATE-LEVEL
COUNTS only -- no physician-level rows leave the package. v3.0.0 keys the active
count on the URPS SUBSPECIALTY certification year (training-accurate); the
authoritative per-provider flag is the `active_2023` column, which we use here
and independently reconcile to the national total (1306).

mufflyaccess owns the workforce COUNTS. Population denominators and access
measures are owned by twostep / isochrones and are documented in the companion
join spec, not shipped as empty columns here.
"""
import csv
import sys
import pyarrow.parquet as pq

PARQUET = sys.argv[1] if len(sys.argv) > 1 else \
    "tests/testthat/fixtures/isochrones-v3.0.0/urps_provider_snapshot.parquet"
OUT = sys.argv[2] if len(sys.argv) > 2 else \
    "share/acs_sheps/out/urps_state_extract_2023_v3.0.0.csv"
SOURCE_COMMIT = "74085a9e695eec5350275a29d8655512ad57422b"
SMALL_CELL = 6

t = pq.read_table(PARQUET)
active = t.column("active_2023").to_pylist()          # v3.0.0 subspecialty-cert basis
st = t.column("state_or_territory").to_pylist()
ic = t.column("is_conus").to_pylist()
bp = t.column("board_pathway").to_pylist()

rows = {}
for a, s, g, p in zip(active, st, ic, bp):
    if not a:
        continue
    d = rows.setdefault(s, {"combined": 0, "abog": 0, "abu": 0, "is_conus": bool(g)})
    d["combined"] += 1
    if p == "ABOG":
        d["abog"] += 1
    elif p == "ABU_NET_NEW":
        d["abu"] += 1

total = sum(d["combined"] for d in rows.values())
assert total == 1306, f"state extract reconstructs to {total}, expected 1306 (v3.0.0)"

with open(OUT, "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow([
        "state_or_territory", "geography_is_conus", "year", "measure",
        "abog_active", "abu_net_new_active", "combined_active",
        "small_cell_flag", "artifact_version", "contract_version", "source_git_commit",
    ])
    for s in sorted(rows):
        d = rows[s]
        w.writerow([
            s, d["is_conus"], 2023, "board_certified_active",
            d["abog"], d["abu"], d["combined"],
            d["combined"] < SMALL_CELL, "3.0.0", "3.0.0", SOURCE_COMMIT,
        ])

print(f"wrote {OUT}: {len(rows)} states, {total} providers (board_certified_active/2023, v3.0.0)")
