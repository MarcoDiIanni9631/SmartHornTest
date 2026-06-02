#!/bin/bash
# step8_annotate.sh <contract.sol>
# Annota il sorgente Solidity con i vincoli trovati dall'analisi.
# Richiede che nella stessa cartella esista un file .vars_z3.txt.
# Produce ContractName.annotated.sol.
#
# Esempio:
#   bash script/step8_annotate.sh test/MyContract/MyContract.sol

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ANNOTATE_SOL="$SCRIPT_DIR/annotate_sol.py"

[ $# -lt 1 ] && { echo "Uso: $0 <contract.sol>"; exit 1; }

SOL="$(readlink -f "$1")"
DIR="$(dirname "$SOL")"

echo "=== STEP 8: annotate → $(basename "$SOL" .sol).annotated.sol ==="
python3 "$ANNOTATE_SOL" "$DIR"
