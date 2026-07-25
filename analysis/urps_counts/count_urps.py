#!/usr/bin/env python3
"""
count_urps.py -- Standard, reproducible count of URPS (and all ABOG OB/GYN
subspecialties) BY YEAR and BY SUBSPECIALTY, with an optional "with urology"
(ABOG + ABU) pathway series, derived from committed isochrones artifacts.

BOARD-ROSTER BASED -- NEVER NPPES taxonomy code alone. Taxonomy self-designation
is incomplete (~51% of certified FPMRS carry 207VF0040X in any NPPES slot) and
would badly undercount. URPS here = ABOG board certification, NPI-matched.

SOURCES (committed, hashable):
  ABOG (required):  manuscript/tables/table1_physician_characteristics.csv
    = ABOG-certified OB/GYN subspecialist cohort, NPI-matched, 2023 active-
      workforce snapshot (analysis_year = 2023). One row per ABOG certificate.
  ABU  (optional):  data/abu_urology/abu_fpmrs_net_new_geocoded_*.csv
    = urology-pathway URPS providers NET-NEW to ABOG (already deduped by NPI).
      The committed map roster carries NO year columns, so by default ABU is
      added as a constant LEVEL SHIFT across years (abu_temporal = false). If an
      ABU roster with cert/retire year columns is supplied, the same active-in-
      year rule is applied and a true ABU time series is produced.

ACTIVE-IN-YEAR RULE (mirrors R/filter_active_providers_for_date.R using the
committed columns): active in year Y iff
    certification_year <= Y  AND  (retirement_year empty OR retirement_year > Y)

OUTPUTS (to --outdir):
  urps_by_year_subspecialty.csv   year x subspecialty x n_active (+ support cols), ABOG
  urps_by_year_pathway.csv        year x pathway {ABOG, ABU, ABOG+ABU} x n_active_urps
  provenance.json                 sources, SHA-256s, rule, flags, caveats

DEFINITIONS: URPS "without urology" = ABOG pathway (this cohort). "with urology" =
ABOG + ABU. CONUS filtering (--conus) excludes the mufflyaccess NON_CONTIGUOUS_CODES
{AK, HI, PR, GU, VI, AS, MP}; off by default so the ABOG count anchors to the
national workforce figure (URPS 2023 = 1031).
"""
import csv, sys, json, hashlib, argparse, collections

YEARS = list(range(2013, 2024))  # config/study_period.yml study window
URPS_LABEL = "Female Pelvic Medicine & Reconstructive Surgery"
# mufflyaccess::NON_CONTIGUOUS_CODES (SSOT) -- kept in sync with that constant.
NON_CONTIGUOUS_CODES = {"HI", "AK", "PR", "GU", "VI", "AS", "MP"}
ABBREV = {
    "Maternal-Fetal Medicine": "MFM",
    "Reproductive Endocrinology and Infertility": "REI",
    "Reproductive Endocrinology & Infertility": "REI",
    "Gynecologic Oncology": "GO",
    "Female Pelvic Medicine & Reconstructive Surgery": "URPS",
    "Minimally Invasive Gynecologic Surgery": "MIGS",
    "Complex Family Planning": "CFP",
    "Pediatric & Adolescent Gynecology": "PAG",
}

def as_int(v):
    v = (v or "").strip()
    if v in ("", "NA", "NaN", "NULL"):
        return None
    try:
        return int(float(v))
    except ValueError:
        return None

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

def load(path):
    return list(csv.DictReader(open(path, newline="", encoding="utf-8", errors="replace")))

def active(cert, ret, y):
    return cert is not None and cert <= y and (ret is None or ret > y)

def main():
    ap = argparse.ArgumentParser(description="Reproducible URPS counts by year / subspecialty / urology pathway.")
    ap.add_argument("table1", help="path to table1_physician_characteristics.csv (ABOG cohort)")
    ap.add_argument("--abu", help="optional ABU (urology-pathway) net-new roster CSV")
    ap.add_argument("--abu-cert-col", default="certification_year")
    ap.add_argument("--abu-retire-col", default="retirement_year")
    ap.add_argument("--conus", action="store_true", help="exclude non-contiguous states (mufflyaccess NON_CONTIGUOUS_CODES)")
    ap.add_argument("--outdir", default=".")
    a = ap.parse_args()

    rows = load(a.table1)
    subcol = "subspecialty_label" if (rows and "subspecialty_label" in rows[0]) else "subspecialty"
    abog = []
    for r in rows:
        st = (r.get("state") or "").strip().upper()
        if a.conus and st in NON_CONTIGUOUS_CODES:
            continue
        abog.append({"sub": (r.get(subcol) or "").strip(),
                     "cert": as_int(r.get("certification_year")),
                     "ret": as_int(r.get("retirement_year")),
                     "npi": (r.get("npi") or "").strip()})
    subspecs = sorted({x["sub"] for x in abog if x["sub"]})

    long_rows = []
    for y in YEARS:
        for s in subspecs:
            sr = [x for x in abog if x["sub"] == s]
            long_rows.append({
                "year": y, "subspecialty": s, "abbrev": ABBREV.get(s, s),
                "n_active": sum(1 for x in sr if active(x["cert"], x["ret"], y)),
                "n_ever_certified_by_year": sum(1 for x in sr if x["cert"] is not None and x["cert"] <= y),
                "n_retired_by_year": sum(1 for x in sr if x["ret"] is not None and x["ret"] <= y),
            })
    out1 = f"{a.outdir}/urps_by_year_subspecialty.csv"
    with open(out1, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["year","subspecialty","abbrev","n_active","n_ever_certified_by_year","n_retired_by_year"])
        w.writeheader(); w.writerows(long_rows)

    abog_urps = {y: sum(1 for x in abog if x["sub"] == URPS_LABEL and active(x["cert"], x["ret"], y)) for y in YEARS}

    abu_info = {"provided": False}
    abu_urps = {y: 0 for y in YEARS}
    if a.abu:
        abu_rows = load(a.abu)
        seen = {x["npi"] for x in abog if x["sub"] == URPS_LABEL and x["npi"]}
        abu = []
        for r in abu_rows:
            st = (r.get("state") or "").strip().upper()
            if a.conus and st in NON_CONTIGUOUS_CODES:
                continue
            npi = (r.get("npi") or "").strip()
            if npi and npi in seen:
                continue
            abu.append({"cert": as_int(r.get(a.abu_cert_col)), "ret": as_int(r.get(a.abu_retire_col)), "npi": npi})
        has_year = any(x["cert"] is not None for x in abu)
        abu_info = {"provided": True, "rows": len(abu_rows), "used": len(abu),
                    "sha256": sha256(a.abu), "temporal": has_year, "source_file": a.abu}
        if has_year:
            abu_urps = {y: sum(1 for x in abu if active(x["cert"], x["ret"], y)) for y in YEARS}
        else:
            n = len(abu)
            abu_urps = {y: n for y in YEARS}

    path_rows = []
    for y in YEARS:
        path_rows.append({"year": y, "pathway": "ABOG", "urology": "without", "n_active_urps": abog_urps[y]})
        if abu_info["provided"]:
            path_rows.append({"year": y, "pathway": "ABU", "urology": "urology_pathway", "n_active_urps": abu_urps[y]})
            path_rows.append({"year": y, "pathway": "ABOG+ABU", "urology": "with", "n_active_urps": abog_urps[y] + abu_urps[y]})
    out2 = f"{a.outdir}/urps_by_year_pathway.csv"
    with open(out2, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["year","pathway","urology","n_active_urps"])
        w.writeheader(); w.writerows(path_rows)

    prov = {
        "generated_by": "count_urps.py",
        "abog_source": a.table1, "abog_sha256": sha256(a.table1), "abog_rows": len(rows),
        "abu": abu_info, "conus_only": a.conus,
        "cohort": "ABOG-certified OB/GYN subspecialists, NPI-matched, 2023 active-workforce snapshot (table1)",
        "subspecialty_column_used": subcol,
        "active_rule": "certification_year <= Y AND (retirement_year empty OR retirement_year > Y)",
        "years": [YEARS[0], YEARS[-1]],
        "urps_without_urology": "ABOG pathway",
        "urps_with_urology": "ABOG + ABU (net-new urology-pathway roster)",
        "abu_snapshot_note": "if the ABU roster has no year columns, ABU is added as a constant level shift across years (abu.temporal=false)",
        "retirement_detection_caveat": "retirement_year populated from ~2016; the 2023-anchored cohort under-represents pre-2016 exits, so 2013-2015 are approximate",
        "outputs": [out1, out2],
    }
    open(f"{a.outdir}/provenance.json", "w").write(json.dumps(prov, indent=2))

    tot = sum(1 for x in abog if active(x["cert"], x["ret"], 2023))
    print(f"ABOG rows {len(rows)} | distinct NPI {len({x['npi'] for x in abog if x['npi']})} | SHA {prov['abog_sha256'][:12]}")
    print(f"ANCHOR total active 2023 (expect 5336 national): {tot}")
    print(f"ANCHOR URPS active 2023  (expect 1031 national): {abog_urps[2023]}")
    if abu_info["provided"]:
        print(f"ABU roster: used {abu_info['used']} rows, temporal={abu_info['temporal']}")
        print(f"URPS with urology 2023: {abog_urps[2023] + abu_urps[2023]}")
    print("URPS (ABOG / without urology) by year:", {y: abog_urps[y] for y in YEARS})
    print("wrote:", out1, "|", out2)

if __name__ == "__main__":
    main()
