#!/usr/bin/env bash
# ==============================================================================
# tools/usage_matrix.sh -- regenerate the RAW cross-repo usage matrix.
#
# Greps every mufflyaccess export (read from NAMESPACE) across each consumer
# repository's R / Rmd sources and prints a Markdown presence table to stdout.
# This keeps docs/CROSS_REPO_USAGE.md honest and reproducible instead of
# hand-maintained.
#
# Usage:
#   tools/usage_matrix.sh <repo_dir> [<repo_dir> ...]
#
# Example (repos checked out side by side):
#   tools/usage_matrix.sh ../isochrones ../twostep ../cliff
#
# Marks:
#   *  a repo that IMPORTS mufflyaccess (library()/requireNamespace()/::) and
#      references the symbol -> "used" (consumes the SSOT).
#   o  a repo that does NOT import mufflyaccess but still references the symbol
#      -> "local" (a pre-promotion original, e.g. the origin repo isochrones).
#   .  the symbol token does not appear.
#
# NOTE: this is a purely textual presence check. Same-named-but-unrelated local
# objects (e.g. cliff's local Nygaard `pfd_prevalence*`) can show up as matches;
# the curated interpretation and such caveats live in docs/CROSS_REPO_USAGE.md.
# ==============================================================================
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
namespace="$here/NAMESPACE"
[ -f "$namespace" ] || { echo "NAMESPACE not found at $namespace" >&2; exit 1; }
[ "$#" -ge 1 ] || { sed -n '2,25p' "$0"; exit 2; }

exports=$(grep -oE '^export\([^)]+\)' "$namespace" | sed -E 's/^export\(|\)$//g')

# --- header ------------------------------------------------------------------
hdr="| Export |"; sep="|---|"
declare -a repos labels imports
for dir in "$@"; do
  label="$(basename "$dir")"
  repos+=("$dir"); labels+=("$label")
  if grep -rqIE 'library\(mufflyaccess\)|requireNamespace\("mufflyaccess"|mufflyaccess::' \
        --include=*.R --include=*.Rmd "$dir" 2>/dev/null; then
    imports+=("yes")
  else
    imports+=("no")
  fi
  hdr+=" $label |"; sep+="---|"
done
printf '%s\n%s\n' "$hdr" "$sep"

# --- one row per export ------------------------------------------------------
for e in $exports; do
  row="| \`$e\` |"
  for i in "${!repos[@]}"; do
    if grep -rqIw --include=*.R --include=*.Rmd -e "$e" "${repos[$i]}" 2>/dev/null; then
      if [ "${imports[$i]}" = "yes" ]; then row+=" * |"; else row+=" o |"; fi
    else
      row+=" . |"
    fi
  done
  printf '%s\n' "$row"
done

# --- import-status footnote --------------------------------------------------
printf '\n'
for i in "${!labels[@]}"; do
  if [ "${imports[$i]}" = "yes" ]; then
    printf '_%s imports mufflyaccess (\\* = consumes the SSOT)._\n' "${labels[$i]}"
  else
    printf '_%s does NOT import mufflyaccess (o = local original / not yet a consumer)._\n' "${labels[$i]}"
  fi
done
