#!/bin/bash
# step3_transform.sh <contract.pl>
# Applica il transform CHC. Richiede che ContractName.aux.pl esista nella stessa cartella.
# Produce ContractName.t.pl e ContractName.t.pl-defs.txt.
#
# Esempio:
#   bash script/step3_transform.sh test/MyContract/MyContract.pl

set -euo pipefail

YULCHC_DIR="/home/labeconomia/mdiianni/verimap_projects/yul-chc"

[ $# -lt 1 ] && { echo "Uso: $0 <contract.pl>"; exit 1; }

PL="$(readlink -f "$1")"
BASE="$(basename "$PL" .pl)"
DIR="$(dirname "$PL")"
AUX="$DIR/$BASE.aux.pl"

[ -f "$AUX" ] || { echo "❌ aux.pl non trovato: $AUX"; exit 1; }

echo "=== STEP 3: transform → $BASE.t.pl ==="
cd "$YULCHC_DIR"
./scripts/transform --interactive "$PL" lib/yul/configs/vcg_multistep.iteration
echo "[OK] $BASE.t.pl generato"
