#!/bin/bash
# step1_grey.sh <contract.sol>
# Compila il contratto Solidity con GREY e produce ContractName.json nella stessa cartella.
#
# Esempio:
#   bash script/step1_grey.sh test/MyContract/MyContract.sol

set -euo pipefail

GREY_DIR="/home/labeconomia/mdiianni/verimap_projects/grey"

[ $# -lt 1 ] && { echo "Uso: $0 <contract.sol>"; exit 1; }

SOL="$(readlink -f "$1")"
BASE="$(basename "$SOL" .sol)"
DIR="$(dirname "$SOL")"
JSON="$DIR/$BASE.json"

echo "=== STEP 1: grey → $BASE.json ==="
cd "$GREY_DIR"
python3 src/grey_main.py -s "$SOL" -v -if sol -o output -solc ./solc-latest
mv "$GREY_DIR/intermediate.json" "$JSON"
echo "[OK] $BASE.json generato"
