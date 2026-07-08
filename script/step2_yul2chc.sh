#!/bin/bash
# step2_yul2chc.sh <contract.json>
# Traduce il JSON in clausole CHC Prolog. Produce ContractName.pl nella stessa cartella.
#
# Esempio:
#   bash script/step2_yul2chc.sh test/MyContract/MyContract.json

set -euo pipefail

YULCHC_DIR="/home/labeconomia/mdiianni/verimap_projects/yul-chc"

[ $# -lt 1 ] && { echo "Uso: $0 <contract.json>"; exit 1; }

JSON="$(readlink -f "$1")"
BASE="$(basename "$JSON" .json)"

echo "=== STEP 2: yul2chc → $BASE.pl ==="
cd "$YULCHC_DIR"
python3 scripts/yul2chc.py -json "$JSON"
echo "[OK] $BASE.pl generato"
