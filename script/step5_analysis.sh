#!/bin/bash
# step5_analysis.sh [options] <contract.t_constr.pl> <target>
# Runs the CHC analysis in the background with nohup. Produces a .zmiout file.
#
# Options:
#   --stop-first-per-loop   one counterexample per loop (recommended)
#   --stop-first            stop at the very first counterexample
#   --timeout SEC           timeout in seconds (default: 300)
#   --maxdepth N            maximum unfolding depth
#   --looplimit N           maximum number of loop iterations
#   --skip-existing         skip if a .zmiout already exists
#   --debug                 verbose output
#
# Example:
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

[ "${#POSITIONAL[@]}" -lt 2 ] && { echo "Usage: $0 [options] <contract.t_constr.pl> <target>"; exit 1; }

CONSTR="$(readlink -f "${POSITIONAL[0]}")"
TARGET="${POSITIONAL[1]}"
BASE="$(basename "$CONSTR" .t_constr.pl)"
DIR="$(dirname "$CONSTR")"

echo "=== STEP 5: analysis → $BASE.*.zmiout (target: $TARGET) ==="
cd "$SCRIPT_DIR"
nohup bash InterpreterAnalysis5.2.sh "${FLAGS[@]+"${FLAGS[@]}"}" "$CONSTR" "$TARGET" \
  > "$DIR/analysis.log" 2>&1 &
echo "[OK] Analysis started in the background (PID: $!)"
echo "     Log: $DIR/analysis.log"
