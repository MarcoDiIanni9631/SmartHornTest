#!/bin/bash
# ====================================================================
# sol2analysis.sh — Full pipeline: .sol → .zmiout → vars + graph
#
# Usage: nohup bash script/sol2analysis.sh [options] <contract.sol> <target> &
#
# Pipeline options:
#   --until-tpl     stop after steps 1-4 (no analysis)
#   --skip-convert  skip steps 1-4 (use existing files)
#   --gen-aux       auto-generate .aux.pl (step 2.5, passed to sol2constr.sh)
#   --aux-hint HINT suggests the function name to sol2tpl.py
#   --varz3         generate .vars_z3.txt after the analysis  (step 6)
#   --varclpq       generate .vars_clpq.txt after the analysis (step 6)
#   --graph         generate the CHC SVG graph             (step 7)
#   --annotate      generate .annotated.sol               (step 8)
#
# Analysis options (passed to InterpreterAnalysis5.2.sh, step 5):
#   --debug, --stop-first, --stop-first-per-loop, --skip-existing
#   --maxdepth N, --looplimit N, --timeout SEC, --skip-file F
#
# Examples:
#   nohup bash script/sol2analysis.sh --stop-first-per-loop --timeout 300 \
#        --varz3 --varclpq --annotate \
#        test/MyContract/MyContract.sol incorrect &
#   bash script/sol2analysis.sh --until-tpl test/MyContract/MyContract.sol
#   bash script/sol2analysis.sh --skip-convert --varz3 --graph \
#        test/MyContract/MyContract.sol incorrect
# ====================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

usage() {
  echo "Usage: $0 [options] <contract.sol> <target>"
  echo "       $0 --until-tpl <contract.sol>"
  exit 1
}

ANALYSIS_FLAGS=()
CONSTR_FLAGS=()
POSITIONAL=()
DO_ANALYSIS=true
DO_VARS=()
DO_GRAPH=false
DO_ANNOTATE=false
SKIP_CONVERT=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --until-tpl)    DO_ANALYSIS=false; shift ;;
    --skip-convert) SKIP_CONVERT=true;  shift ;;
    --gen-aux)      CONSTR_FLAGS+=("$1"); shift ;;
    --aux-hint)     CONSTR_FLAGS+=("$1" "$2"); shift 2 ;;
    --varz3)        DO_VARS+=("z3");    shift ;;
    --varclpq)      DO_VARS+=("clpq");  shift ;;
    --graph)        DO_GRAPH=true;      shift ;;
    --annotate)     DO_ANNOTATE=true;   shift ;;
    --debug|--stop-first|--stop-first-per-loop|--skip-existing)
      ANALYSIS_FLAGS+=("$1"); shift ;;
    --maxdepth|--looplimit|--timeout|--skip-file)
      ANALYSIS_FLAGS+=("$1" "$2"); shift 2 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

if $DO_ANALYSIS; then
  [ "${#POSITIONAL[@]}" -eq 2 ] || usage
  SOL="${POSITIONAL[0]}"; TARGET="${POSITIONAL[1]}"
else
  [ "${#POSITIONAL[@]}" -eq 1 ] || usage
  SOL="${POSITIONAL[0]}"; TARGET=""
fi

SOL="$(readlink -f "$SOL")"
[ -f "$SOL" ] || { echo "❌ File not found: $SOL"; exit 1; }

BASE="$(basename "$SOL" .sol)"
DIR="$(dirname "$SOL")"

# ------------------------------------------------------------------
# STEP 1-4: CONVERSION
# ------------------------------------------------------------------
if $SKIP_CONVERT; then
  echo "⏭️  Conversion skipped (--skip-convert)"
  [ -f "$DIR/$BASE.t_constr.pl" ] || { echo "❌ $BASE.t_constr.pl not found"; exit 1; }
else
  bash "$SCRIPT_DIR/sol2constr.sh" "${CONSTR_FLAGS[@]+"${CONSTR_FLAGS[@]}"}" "$SOL"
fi

# ------------------------------------------------------------------
# STEP 7 (optional): CHC GRAPH
# ------------------------------------------------------------------
if $DO_GRAPH; then
  echo ""
  bash "$SCRIPT_DIR/step7_graph.sh" "$DIR/$BASE.t.pl"
fi

# Stop here if --until-tpl
if ! $DO_ANALYSIS; then
  echo ""
  echo "✅ Conversion complete (--until-tpl)"
  exit 0
fi

# ------------------------------------------------------------------
# STEP 5: ANALYSIS (synchronous — waits before running step 6)
# ------------------------------------------------------------------
echo ""
echo "=================================================="
echo "🔍 ANALYSIS: $BASE.t_constr.pl → target: $TARGET"
echo "=================================================="
cd "$SCRIPT_DIR"
bash InterpreterAnalysis5.2.sh "${ANALYSIS_FLAGS[@]+"${ANALYSIS_FLAGS[@]}"}" \
  "$DIR/$BASE.t_constr.pl" "$TARGET"

# ------------------------------------------------------------------
# STEP 6: VARS + JSON (z3 and clpq always)
# ------------------------------------------------------------------
ZMIOUT=$(ls -t "$DIR"/*.zmiout 2>/dev/null | head -1 || true)
if [ -z "$ZMIOUT" ]; then
  echo "⚠️  No .zmiout found in $DIR, skipping step 6"
else
  DEFS="$DIR/$BASE.t.pl-defs.txt"
  echo ""
  bash "$SCRIPT_DIR/step6_vars.sh" --z3 --clpq "$SOL" "$DEFS" "$ZMIOUT"
fi

# ------------------------------------------------------------------
# STEP 8 (optional): ANNOTATE
# ------------------------------------------------------------------
if $DO_ANNOTATE; then
  echo ""
  bash "$SCRIPT_DIR/step8_annotate.sh" "$SOL"
fi

echo ""
echo "=================================================="
echo "✅ Pipeline complete!"
echo "=================================================="
