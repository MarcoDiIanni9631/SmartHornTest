#!/bin/bash
# ====================================================================
# sol2analysis.sh — Pipeline completa: .sol → .zmiout → vars + grafo
#
# Uso: nohup bash script/sol2analysis.sh [opzioni] <contratto.sol> <target> &
#
# Opzioni pipeline:
#   --until-tpl     ferma dopo i step 1-4 (no analisi)
#   --skip-convert  salta i step 1-4 (usa file esistenti)
#   --gen-aux       genera .aux.pl automaticamente (step 2.5, passato a sol2constr.sh)
#   --aux-hint HINT suggerisce il nome della funzione a sol2tpl.py
#   --varz3         genera .vars_z3.txt dopo l'analisi  (step 6)
#   --varclpq       genera .vars_clpq.txt dopo l'analisi (step 6)
#   --graph         genera il grafo CHC SVG             (step 7)
#   --annotate      genera .annotated.sol               (step 8)
#
# Opzioni analisi (passate a InterpreterAnalysis5.2.sh, step 5):
#   --debug, --stop-first, --stop-first-per-loop, --skip-existing
#   --maxdepth N, --looplimit N, --timeout SEC, --skip-file F
#
# Esempi:
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
  echo "Uso: $0 [opzioni] <contratto.sol> <target>"
  echo "     $0 --until-tpl <contratto.sol>"
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
[ -f "$SOL" ] || { echo "❌ File non trovato: $SOL"; exit 1; }

BASE="$(basename "$SOL" .sol)"
DIR="$(dirname "$SOL")"

# ------------------------------------------------------------------
# STEP 1-4: CONVERSIONE
# ------------------------------------------------------------------
if $SKIP_CONVERT; then
  echo "⏭️  Conversione saltata (--skip-convert)"
  [ -f "$DIR/$BASE.t_constr.pl" ] || { echo "❌ $BASE.t_constr.pl non trovato"; exit 1; }
else
  bash "$SCRIPT_DIR/sol2constr.sh" "${CONSTR_FLAGS[@]+"${CONSTR_FLAGS[@]}"}" "$SOL"
fi

# ------------------------------------------------------------------
# STEP 7 (opzionale): GRAFO CHC
# ------------------------------------------------------------------
if $DO_GRAPH; then
  echo ""
  bash "$SCRIPT_DIR/step7_graph.sh" "$DIR/$BASE.t.pl"
fi

# Ferma qui se --until-tpl
if ! $DO_ANALYSIS; then
  echo ""
  echo "✅ Conversione completata (--until-tpl)"
  exit 0
fi

# ------------------------------------------------------------------
# STEP 5: ANALISI (sincrona — aspetta la fine prima di step 6)
# ------------------------------------------------------------------
echo ""
echo "=================================================="
echo "🔍 ANALISI: $BASE.t_constr.pl → target: $TARGET"
echo "=================================================="
cd "$SCRIPT_DIR"
bash InterpreterAnalysis5.2.sh "${ANALYSIS_FLAGS[@]+"${ANALYSIS_FLAGS[@]}"}" \
  "$DIR/$BASE.t_constr.pl" "$TARGET"

# ------------------------------------------------------------------
# STEP 6: VARS + JSON (z3 e clpq sempre)
# ------------------------------------------------------------------
ZMIOUT=$(ls -t "$DIR"/*.zmiout 2>/dev/null | head -1 || true)
if [ -z "$ZMIOUT" ]; then
  echo "⚠️  Nessun .zmiout trovato in $DIR, skip step 6"
else
  DEFS="$DIR/$BASE.t.pl-defs.txt"
  echo ""
  bash "$SCRIPT_DIR/step6_vars.sh" --z3 --clpq "$SOL" "$DEFS" "$ZMIOUT"
fi

# ------------------------------------------------------------------
# STEP 8 (opzionale): ANNOTATE
# ------------------------------------------------------------------
if $DO_ANNOTATE; then
  echo ""
  bash "$SCRIPT_DIR/step8_annotate.sh" "$SOL"
fi

echo ""
echo "=================================================="
echo "✅ Pipeline completata!"
echo "=================================================="
