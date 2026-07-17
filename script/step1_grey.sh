#!/bin/bash
# step1_grey.sh <contract.sol>
# Compila il contratto Solidity con GREY e produce ContractName.json nella stessa cartella.
#
# Esempio:
#   bash script/step1_grey.sh test/MyContract/MyContract.sol

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
source "$SCRIPT_DIR/config.sh"

[ $# -lt 1 ] && { echo "Uso: $0 <contract.sol>"; exit 1; }
[ -d "$GREY_DIR" ] || { echo "❌ GREY_DIR non trovato: $GREY_DIR (clona costa-group/grey lì, o imposta GREY_DIR)"; exit 1; }

SOL="$(readlink -f "$1")"
BASE="$(basename "$SOL" .sol)"
DIR="$(dirname "$SOL")"
JSON="$DIR/$BASE.json"

echo "=== STEP 1: grey → $BASE.json ==="
cd "$GREY_DIR"
python3 src/grey_main.py -s "$SOL" -v -if sol -o output -solc ./solc-latest
mv "$GREY_DIR/intermediate.json" "$JSON"
echo "[OK] $BASE.json generato"
