#!/bin/bash
# step4_constr.sh <contract.t.pl>
# Riscrive le operazioni aritmetiche in forma constr(). Produce ContractName.t_constr.pl.

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

[ $# -lt 1 ] && { echo "Uso: $0 <contract.t.pl>"; exit 1; }

TPL="$(readlink -f "$1")"
BASE="$(basename "$TPL" .t.pl)"

echo "=== STEP 4: constr → $BASE.t_constr.pl ==="
python3 "$SCRIPT_DIR/yulPl2Constr.py" "$TPL"
echo "[OK] $BASE.t_constr.pl generato"
