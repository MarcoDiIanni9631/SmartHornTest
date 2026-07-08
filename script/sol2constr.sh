#!/bin/bash
# ============================================================
# sol2constr.sh — Steps 1–4: Solidity → .t_constr.pl
#
# Uso: bash sol2constr.sh [opzioni] <contratto.sol>
#
# Opzioni:
#   --gen-aux           genera .aux.pl automaticamente (step 2.5)
#   --aux-hint HINT     suggerisce il nome della funzione a sol2tpl.py
#
# Chiama in sequenza:
#   step1_grey.sh      → .json
#   step2_yul2chc.sh   → .pl
#   [step2.5: sol2tpl  → .aux.pl]  (solo con --gen-aux)
#   step3_transform.sh → .t.pl  (richiede .aux.pl nella stessa cartella)
#   step4_constr.sh    → .t_constr.pl
#
# Ogni step gestisce autonomamente l'esecuzione sul server se necessario.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

GEN_AUX=false
AUX_HINT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --gen-aux)  GEN_AUX=true; shift ;;
    --aux-hint) AUX_HINT="$2"; shift 2 ;;
    *) break ;;
  esac
done

[ "$#" -lt 1 ] && { echo "Uso: $0 [--gen-aux] [--aux-hint HINT] <contratto.sol>"; exit 1; }

SOL="$(readlink -f "$1")"
[ -f "$SOL" ] || { echo "❌ File non trovato: $SOL"; exit 1; }

BASE="$(basename "$SOL" .sol)"
DIR="$(dirname "$SOL")"

echo "=================================="
echo "📜 Contratto: $BASE.sol"
echo "📂 Cartella:  $DIR"
echo "=================================="
echo ""

bash "$SCRIPT_DIR/step1_grey.sh"    "$SOL"
echo ""
bash "$SCRIPT_DIR/step2_yul2chc.sh" "$DIR/$BASE.json"

if $GEN_AUX; then
  echo ""
  echo "=== STEP 2.5: sol2tpl → $BASE.aux.pl ==="
  python3 - "$DIR/$BASE.pl" "$AUX_HINT" "$SCRIPT_DIR" << 'PYEOF'
import sys
sys.path.insert(0, sys.argv[3])
from sol2tpl import parse_fun_declarations, choose_function, generate_aux_pl
import os
pl_path = sys.argv[1]
hint    = sys.argv[2] if (len(sys.argv) > 2 and sys.argv[2]) else None
funs    = parse_fun_declarations(pl_path)
fun     = choose_function(funs, hint)
aux     = os.path.splitext(pl_path)[0] + '.aux.pl'
sol     = os.path.splitext(pl_path)[0] + '.sol'
generate_aux_pl(aux, fun, sol)
print('[OK] aux.pl generato (fun: ' + fun['name'] + ')')
PYEOF
fi

echo ""
bash "$SCRIPT_DIR/step3_transform.sh" "$DIR/$BASE.pl"
echo ""
bash "$SCRIPT_DIR/step4_constr.sh"    "$DIR/$BASE.t.pl"

echo ""
echo "=================================="
echo "✅ Conversione completata!"
echo "   → $DIR/$BASE.t_constr.pl"
echo "=================================="
