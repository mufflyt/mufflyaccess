#!/usr/bin/env python3
"""
freshness_check.py -- is the committed URPS / subspecialist count set CURRENT
relative to its isochrones source?

Freshness is defined by SHA-256: provenance.json records the hash of the exact
table1_physician_characteristics.csv that produced the committed CSVs. This tool
re-hashes the current source and compares.

  FRESH  (exit 0): current source hash == recorded hash -> CSVs reflect source.
  STALE  (exit 1): source changed since the CSVs were built -> regenerate.
  ERROR  (exit 2): source not found / provenance unreadable.

With --regenerate, a STALE result re-runs count_urps.py and rewrites the CSVs +
provenance (so the counts move only when the source actually moved).

NOTE: this checks that the DERIVED counts match the current table1. It does NOT
rebuild table1 itself -- that is the isochrones pipeline (fresh NPPES + board
rosters + R/geospatial toolchain), which runs where that data lives.
"""
import sys, os, json, hashlib, argparse, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SRC = "/workspace/isochrones/manuscript/tables/table1_physician_characteristics.csv"

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for c in iter(lambda: fh.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default=DEFAULT_SRC, help="path to table1_physician_characteristics.csv")
    ap.add_argument("--provenance", default=os.path.join(HERE, "provenance.json"))
    ap.add_argument("--regenerate", action="store_true", help="rebuild CSVs if STALE")
    a = ap.parse_args()

    try:
        recorded = json.load(open(a.provenance))["abog_sha256"]
    except Exception as e:
        print(f"ERROR: cannot read recorded hash from {a.provenance}: {e}"); return 2
    if not os.path.exists(a.source):
        print(f"ERROR: source not found: {a.source}\n  (clone isochrones or pass --source)"); return 2

    current = sha256(a.source)
    print(f"source     : {a.source}")
    print(f"recorded   : {recorded}")
    print(f"current    : {current}")
    if current == recorded:
        print("STATUS     : FRESH  (counts reflect the current source)"); return 0

    print("STATUS     : STALE  (source changed since the counts were built)")
    if not a.regenerate:
        print("  run with --regenerate to rebuild, or re-run count_urps.py"); return 1

    print("regenerating via count_urps.py ...")
    r = subprocess.run([sys.executable, os.path.join(HERE, "count_urps.py"), a.source,
                        "--outdir", HERE])
    if r.returncode != 0:
        print("ERROR: count_urps.py failed"); return 2
    new = json.load(open(a.provenance))["abog_sha256"]
    print(f"rebuilt    : {new}")
    print("STATUS     : REFRESHED" if new == current else "STATUS: STILL STALE (investigate)")
    return 0 if new == current else 2

if __name__ == "__main__":
    sys.exit(main())
