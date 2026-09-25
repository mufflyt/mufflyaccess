#!/usr/bin/env python3
"""Static QA for the mufflyaccess R package -- reproduces the CI quality gates
that do not require an R runtime, for a fast local check before pushing.

It does NOT replace CI (which additionally runs testthat, R CMD check, lintr,
spelling via hunspell, roxygen2 regeneration and pkgdown -- all of which need
R). It reproduces the text-analysis gates faithfully and gives structural
equivalents for the doc-sync gates:

  * deps-declared   faithful: every pkg:: / library() in R/ + tests/ is declared
                    in DESCRIPTION (mirrors .github/workflows/ci.yml deps-declared)
  * api-surface     faithful: tests/testthat/api-surface.txt == NAMESPACE exports,
                    de-duplicated, and in the file's collation
  * docs-in-sync    structural: @export tags reconcile with NAMESPACE exports
                    (a true check needs roxygen2::roxygenise())
  * man-coverage    every export has a man/*.Rd \\alias; no duplicate aliases
  * hygiene         no TODO/FIXME/XXX markers left in R/

Exit status is non-zero if any FAIL-level finding is present.

Usage:  python3 tools/qa_static.py        # from the repo root, or anywhere
"""
import os
import re
import glob
import sys

# Repo root = parent of this tools/ directory, so it runs from anywhere.
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

findings = []  # (severity, check, message)


def add(sev, chk, msg):
    findings.append((sev, chk, msg))


# ---------------------------------------------------------------- NAMESPACE ---
ns = open("NAMESPACE").read()
ns_exports = set(re.findall(r"^export\(([^)]+)\)", ns, re.M))
ns_s3 = set(re.findall(r"^S3method\(([^)]+)\)", ns, re.M))

# ---------------------------------------- CHECK 1: deps-declared (FAITHFUL) ---
dcf = open("DESCRIPTION").read()


def dcf_field(name):
    m = re.search(rf"^{name}:(.*?)(?=^\S|\Z)", dcf, re.M | re.S)
    if not m:
        return []
    return [re.sub(r"\s*\(.*", "", p).strip()
            for p in m.group(1).split(",") if p.strip()]


declared = set()
for f in ("Depends", "Imports", "Suggests", "LinkingTo"):
    declared |= {d for d in dcf_field(f) if d}
pkg_name = re.search(r"^Package:\s*(\S+)", dcf, re.M).group(1)
declared |= {"R", "base", "methods", pkg_name}

used = set()
files = (glob.glob("R/**/*.R", recursive=True)
         + glob.glob("tests/**/*.R", recursive=True))
for f in files:
    for ln in open(f, errors="replace"):
        if re.match(r"^\s*#", ln):
            continue
        used |= set(re.findall(r"[A-Za-z][A-Za-z0-9.]*(?=::)", ln))
        for m in re.findall(r"(?:library|require)\(([^)]*)\)", ln):
            used.add(m.replace('"', "").replace("'", "").strip())
used = {u for u in used if u and re.fullmatch(r"[A-Za-z0-9.]+", u)}
missing = sorted(used - declared)
if missing:
    add("FAIL", "deps-declared",
        "Undeclared package(s) referenced in R/ or tests/: " + ", ".join(missing))
else:
    add("ok", "deps-declared",
        f"all {len(used)} referenced package(s) declared in DESCRIPTION")

# ------------------------------------- CHECK 2: api-surface.txt vs NAMESPACE ---
surf = [l.strip() for l in open("tests/testthat/api-surface.txt")
        if l.strip() and not l.startswith("#")]
surf_set = set(surf)
only_ns = sorted(ns_exports - surf_set)
only_surf = sorted(surf_set - ns_exports)
if only_ns:
    add("FAIL", "api-surface",
        "Exported but MISSING from api-surface.txt: " + ", ".join(only_ns))
if only_surf:
    add("FAIL", "api-surface",
        "In api-surface.txt but NOT exported: " + ", ".join(only_surf))
if not only_ns and not only_surf:
    add("ok", "api-surface",
        f"api-surface.txt matches all {len(ns_exports)} NAMESPACE exports")
if len(surf) != len(surf_set):
    dups = sorted({x for x in surf if surf.count(x) > 1})
    add("FAIL", "api-surface", "Duplicate entries in api-surface.txt: " + ", ".join(dups))
# collation the file is kept in: case-folded, "_" before digits/letters
key = lambda s: s.lower().replace("_", "\x01")
if sorted(surf, key=key) != surf:
    add("WARN", "api-surface", "api-surface.txt is not in the expected sort order")

# --------------------------- CHECK 3: @export tags vs NAMESPACE (structural) ---
export_tagged = set()
for f in glob.glob("R/**/*.R", recursive=True):
    lines = open(f, errors="replace").read().splitlines()
    for i, ln in enumerate(lines):
        if not re.match(r"^#'\s*@export\b", ln):
            continue
        m2 = re.match(r"^#'\s*@export\s+(\S+)", ln)
        if m2:
            export_tagged.add(m2.group(1))
            continue
        for j in range(i + 1, min(i + 40, len(lines))):
            if lines[j].startswith("#'"):
                continue
            a = re.match(r'^\s*(?:"([^"]+)"|`([^`]+)`|([A-Za-z.][A-Za-z0-9._]*))'
                         r'\s*(?:<-|=)\s*', lines[j])
            if a:
                export_tagged.add(a.group(1) or a.group(2) or a.group(3))
            break
tag_only = sorted(export_tagged - ns_exports - ns_s3)
if tag_only:
    add("WARN", "docs-in-sync",
        "@export tag with no matching NAMESPACE export "
        "(parser may miss dynamically-assigned names): " + ", ".join(tag_only))
else:
    add("ok", "docs-in-sync", "@export tags reconcile with NAMESPACE exports")

# --------------------------------- CHECK 4: man/ coverage of exports -----------
rd_alias = {}
for rd in glob.glob("man/*.Rd"):
    for al in re.findall(r"\\alias\{([^}]+)\}", open(rd, errors="replace").read()):
        rd_alias.setdefault(al, []).append(os.path.basename(rd))
undocumented = sorted(e for e in ns_exports if e not in rd_alias)
if undocumented:
    add("FAIL", "man-coverage", "Exported but NO man/*.Rd alias: " + ", ".join(undocumented))
else:
    add("ok", "man-coverage", f"every one of {len(ns_exports)} exports has a man/ page")
dup_alias = sorted(a for a, fs in rd_alias.items() if len(fs) > 1)
if dup_alias:
    add("WARN", "man-coverage", "alias documented in >1 Rd: " + ", ".join(dup_alias))

# --------------------------------- CHECK 5: hygiene ---------------------------
todo = []
for f in glob.glob("R/**/*.R", recursive=True):
    for i, ln in enumerate(open(f, errors="replace")):
        if re.search(r"\b(TODO|FIXME|XXX|HACK)\b", ln):
            todo.append(f"{f}:{i + 1}")
if todo:
    add("info", "hygiene", f"{len(todo)} TODO/FIXME/XXX marker(s) in R/ (first: {todo[0]})")
else:
    add("ok", "hygiene", "no TODO/FIXME/XXX markers in R/")

# ---------------------------------------------------------------- report ------
order = {"FAIL": 0, "WARN": 1, "info": 2, "ok": 3}
findings.sort(key=lambda x: order[x[0]])
nfail = sum(1 for s, _, _ in findings if s == "FAIL")
nwarn = sum(1 for s, _, _ in findings if s == "WARN")
print("=" * 72)
print(f"  mufflyaccess static QA  —  {len(files)} R/tests files, {len(ns_exports)} exports")
print("=" * 72)
tags = {"FAIL": "x FAIL", "WARN": "! WARN", "info": ". info", "ok": "  ok  "}
for sev, chk, msg in findings:
    print(f"{tags[sev]}  [{chk}] {msg}")
print("-" * 72)
print(f"  {nfail} FAIL, {nwarn} WARN")
sys.exit(1 if nfail else 0)
