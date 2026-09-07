#!/bin/bash
# step10_sol_cfg.sh <contract.sol>
# Genera, con slither, il control-flow graph per ogni funzione del contratto
# (complementare al grafo CHC di step7: qui si vede il livello sorgente
# Solidity, non i predicati Horn). Produce un .html interattivo per funzione
# più un index.html, tutti in dot_dias/sol_cfg/.
#
# Esempio:
#   bash script/step10_sol_cfg.sh test/MyContract/MyContract.sol

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
source "$SCRIPT_DIR/config.sh"

[ $# -lt 1 ] && { echo "Usage: $0 <contract.sol>"; exit 1; }
[ -n "$SLITHER_BIN" ] || {
    echo "❌ slither not found. Clone github.com/crytic/slither as a sibling folder and install it into its myenv/ (Python >= 3.10), or set SLITHER_PY/SLITHER_BIN."
    exit 1
}

[ -f "$1" ] || { echo "❌ file not found: $1 (wrong machine? this path must be reachable from wherever you're running this script)"; exit 1; }

SOL="$(readlink -f "$1")"
BASE="$(basename "$SOL" .sol)"
DIR="$(dirname "$SOL")"
OUTDIR="$DIR/dot_dias/sol_cfg"

# step9 --all-tests names its index this way (same $BASE, since <Base>.sol and
# <Base>.t.pl share a stem); link to it if it's already been generated.
CHC_INDEX="$DIR/dot_dias/${BASE}_alltests_index.html"
BACK_HREF=""
[ -f "$CHC_INDEX" ] && BACK_HREF="../${BASE}_alltests_index.html"

echo "=== STEP 10: slither → Solidity CFG(s) ==="
mkdir -p "$OUTDIR"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cp "$SOL" "$WORKDIR/"

( cd "$WORKDIR" && $SLITHER_BIN "$(basename "$SOL")" --print cfg ) || {
    echo "⚠️  slither exited non-zero (contracts with warnings still usually produce .dot files, continuing)"
}

shopt -s nullglob
DOTS=("$WORKDIR"/*.dot)
shopt -u nullglob
[ ${#DOTS[@]} -gt 0 ] || { echo "❌ slither produced no .dot files"; exit 1; }

{
    echo "<!doctype html><meta charset='utf-8'><title>${BASE} — Solidity CFG</title>"
    echo "<body style='font-family:sans-serif;max-width:640px;margin:40px auto'>"
    echo "<h2>${BASE} — control-flow graph per function</h2>"
    [ -n "$BACK_HREF" ] && echo "<p><a href=\"$BACK_HREF\">&larr; CHC graph</a></p>"
    echo "<ul>"
} > "$OUTDIR/index.html"

for dot in "${DOTS[@]}"; do
    fname="$(basename "$dot")"
    cp "$dot" "$OUTDIR/$fname"
    svg="$OUTDIR/${fname}.svg"
    html_out="$OUTDIR/${fname%.dot}.html"
    dot -Tsvg "$OUTDIR/$fname" -o "$svg"
    BACK_ARGS=()
    [ -n "$BACK_HREF" ] && BACK_ARGS=(--back-href "$BACK_HREF")
    python3 "$SCRIPT_DIR/sol_cfg2html.py" "$OUTDIR/$fname" --svg "$svg" -o "$html_out" --sol "$SOL" "${BACK_ARGS[@]}"
    # slither names files "<contract>.sol-<Contract>-<function>(...).dot" — keep
    # only the function signature part for the index label.
    label="${fname#*-}"
    label="${label%.dot}"
    echo "<li><a href=\"$(basename "$html_out")\">${label}</a></li>" >> "$OUTDIR/index.html"
done

echo "</ul></body>" >> "$OUTDIR/index.html"
echo "[OK] Index → $OUTDIR/index.html"
