#!/bin/bash
# step7_graph.sh <contract.t.pl>
# Genera il grafo CHC con chcviz. Produce un SVG in dot_dias/.
#
# Esempio:
#   bash script/step7_graph.sh test/MyContract/MyContract.t.pl

set -euo pipefail

[ $# -lt 1 ] && { echo "Uso: $0 <contract.t.pl>"; exit 1; }

TPL="$(readlink -f "$1")"
BASE="$(basename "$TPL" .pl)"
DIR="$(dirname "$TPL")"

echo "=== STEP 7: chcviz → grafo SVG ==="
chcviz "$TPL" 2>&1 | grep -v '^%\|^Warning\|^\$' || true

SVG="$DIR/dot_dias/${BASE}_clean_object_xref_diagram.dot.svg"
[ -f "$SVG" ] && echo "[OK] SVG → $SVG" || echo "⚠️  SVG non trovato: $SVG"
