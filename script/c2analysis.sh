#!/bin/bash
# c2analysis.sh <contract.c> [target] [timeout_seconds]
#
# Pipeline C legacy end-to-end: .c -> VeriMAP (smallstep) -> VeriMAP (smt)
# -> smt2map -> InterpreterAnalysis5.2.sh. Tutti gli intermedi finiscono
# nella stessa cartella del .c (VeriMAP lavora sempre accanto al sorgente).
#
# target: default "incorrect" (NON "ff" -- vedi fonte.txt di TRACER_test3_unsafe
#         per il perche': "ff" e' dichiarato ma senza corpo nell'output di
#         smt2map con questa versione del toolchain, "incorrect" e' quello
#         che ha davvero la clausola derivata da VeriMAP).
#
# Esempio:
#   bash script/c2analysis.sh /path/to/prog.c
#   bash script/c2analysis.sh /path/to/prog.c incorrect 60

set -uo pipefail

VERIMAP_DIR=/home/marco/remote_verimap/VeriMAP-linux_x86_64
SMT2MAP_DIR=/home/marco/remote_verimap/verimap
INTERP_DIR=/home/marco/remote_verimap/smarthorntest/script

[ $# -lt 1 ] && { echo "Usage: $0 <contract.c> [target] [timeout_seconds]"; exit 1; }

FILE="$(readlink -f "$1")"
TARGET="${2:-incorrect}"
TIMEOUT="${3:-60}"
NAME="$(basename "$FILE" .c)"

[ -f "$FILE" ] || { echo "❌ [$NAME] file not found: $FILE"; exit 1; }

echo "=== [$NAME] STEP 1/4: VeriMAP -v smallstep ==="
( cd "$VERIMAP_DIR" && ./VeriMAP "$FILE" -v smallstep )
TPL="$FILE.transform.pl"
if [ ! -s "$TPL" ] || ! grep -q "^incorrect" "$TPL"; then
  echo "❌ [$NAME] STEP 1 FAILED — $TPL missing/empty/no 'incorrect' clause"
  exit 2
fi

echo "=== [$NAME] STEP 2/4: VeriMAP -o smt ==="
( cd "$VERIMAP_DIR" && ./VeriMAP "$TPL" -o smt )
SMT="$FILE.transform.smt"
if [ ! -s "$SMT" ]; then
  echo "❌ [$NAME] STEP 2 FAILED — $SMT missing/empty"
  exit 3
fi

echo "=== [$NAME] STEP 3/4: smt2map ==="
( cd "$SMT2MAP_DIR" && ./scripts/smt2map "$SMT" )
SMT2PL="$SMT.smt2.pl"
if [ ! -s "$SMT2PL" ]; then
  echo "❌ [$NAME] STEP 3 FAILED — $SMT2PL missing/empty"
  exit 4
fi

echo "=== [$NAME] STEP 4/4: InterpreterAnalysis5.2.sh (target: $TARGET, timeout: ${TIMEOUT}s) ==="
( cd "$INTERP_DIR" && bash InterpreterAnalysis5.2.sh --timeout "$TIMEOUT" "$SMT2PL" "$TARGET" )
ZM=$(ls "$SMT2PL."*.zmiout 2>/dev/null | head -1)
if [ -z "$ZM" ]; then
  echo "❌ [$NAME] STEP 4 FAILED — no .zmiout produced"
  exit 5
fi

NTESTS=$(grep -c "^===.*TEST #" "$ZM")
VERDICT=$(basename "$ZM" | grep -oE "nonDerivable|derivable" | head -1)

echo ""
echo "✅ [$NAME] RESULT: $VERDICT ($NTESTS test found) -> $ZM"
