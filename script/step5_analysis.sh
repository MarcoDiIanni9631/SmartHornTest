#!/bin/bash
# step5_analysis.sh [opzioni] <contract.t_constr.pl> <target>
# Lancia l'analisi CHC in background con nohup. Produce un file .zmiout.
#
# Opzioni:
#   --stop-first-per-loop   un controesempio per loop (consigliato)
#   --stop-first            ferma al primo controesempio in assoluto
#   --timeout SEC           timeout in secondi (default: 300)
#   --maxdepth N            profondita massima di unfolding
#   --looplimit N           numero massimo di iterazioni del loop
#   --skip-existing         salta se esiste gia un .zmiout
#   --debug                 output verboso
#
# Esempio:
#   bash script/step5_analysis.sh --stop-first-per-loop --timeout 300 \
#     test/MyContract/MyContract.t_constr.pl incorrect

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

FLAGS=()
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --stop-first|--stop-first-per-loop|--skip-existing|--debug)
      FLAGS+=("$1"); shift ;;
    --timeout|--maxdepth|--looplimit|--skip-file)
      FLAGS+=("$1" "$2"); shift 2 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

[ "${#POSITIONAL[@]}" -lt 2 ] && { echo "Uso: $0 [opzioni] <contract.t_constr.pl> <target>"; exit 1; }

CONSTR="$(readlink -f "${POSITIONAL[0]}")"
TARGET="${POSITIONAL[1]}"
BASE="$(basename "$CONSTR" .t_constr.pl)"
DIR="$(dirname "$CONSTR")"

echo "=== STEP 5: analisi → $BASE.*.zmiout (target: $TARGET) ==="
cd "$SCRIPT_DIR"
nohup bash InterpreterAnalysis5.2.sh "${FLAGS[@]}" "$CONSTR" "$TARGET" \
  > "$DIR/analysis.log" 2>&1 &
echo "[OK] Analisi avviata in background (PID: $!)"
echo "     Log: $DIR/analysis.log"
