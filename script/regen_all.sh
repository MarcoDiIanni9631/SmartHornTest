#!/bin/bash
# regen_all.sh <cartella_destinazione> [file1.sol file2.sol ...]
#
# Rigenera da zero (Solidity -> GREY -> yul2chc -> transform -> constr ->
# analisi Z3/CLP(Q) -> vars/json), un contratto alla volta
# (MAI GREY in concorrenza -- .../grey/intermediate.json e' condiviso e si
# corrompe se due invocazioni girano insieme), tutti i .sol trovati dentro
# <cartella_destinazione>/*/<nome_cartella>.sol (oppure, se passati come
# argomenti extra, copia prima quei file .sol dentro <cartella_destinazione>,
# uno per sottocartella, prima di partire).
#
# Uso tipico per una NUOVA cartella di test:
#   mkdir nuovaCartella
#   for f in path/a/*.sol path/b/*.sol; do
#     name=$(basename "$f" .sol)
#     mkdir -p "nuovaCartella/$name"
#     cp "$f" "nuovaCartella/$name/"
#   done
#   bash script/regen_all.sh nuovaCartella
#
# L'hint (--aux-hint, il nome/prefisso della funzione pubblica da
# analizzare) di default e' "_f_". Se un contratto ha la funzione pubblica
# con un altro nome, aggiungilo a HINTS qui sotto (o esporta la variabile
# REGEN_HINTS_FILE con un file bash che definisce lo stesso array prima di
# lanciare questo script).
set -uo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

NEWDIR="${1:?Uso: $0 <cartella_destinazione>}"
LOGDIR="${REGEN_LOGDIR:-/tmp/regen_logs_$(basename "$NEWDIR")}"
mkdir -p "$LOGDIR"

declare -A HINTS=(
  [short_circuit_and_fail]="_g_"
  [short_circuit_and_need_both_fail]="_g_"
  [Math_max]="_max_"
  [Math_min]="_min_"
  [Math_average]="_average_"
  [simple_if]="_simple_if_"
)
if [ -n "${REGEN_HINTS_FILE:-}" ] && [ -f "$REGEN_HINTS_FILE" ]; then
  source "$REGEN_HINTS_FILE"
fi

for d in "$NEWDIR"/*/; do
  name=$(basename "$d")
  sol="$d/$name.sol"
  [ -f "$sol" ] || continue
  hint="${HINTS[$name]:-_f_}"
  # REGEN_SKIP_DONE=1: salta i contratti che hanno gia' un .zmiout (per
  # riprendere un lancio interrotto senza rifare quelli finiti)
  if [ "${REGEN_SKIP_DONE:-0}" = 1 ] && ls "$d"*.zmiout >/dev/null 2>&1; then
    echo "===== $name: gia' fatto, saltato ====="
    continue
  fi
  echo "===== $name (hint=$hint) ====="
  bash script/sol2analysis.sh --gen-aux --aux-hint "$hint" --varz3 --varclpq --timeout 60 \
    "$sol" incorrect > "$LOGDIR/regen_${name}.log" 2>&1
  z=$(ls "$d"*.zmiout 2>/dev/null | head -1)
  if [ -n "$z" ]; then
    verdict=$(basename "$z" | grep -oE "nonDerivable|derivable")
    ntests=$(grep -c "TEST #" "$z")
    echo "  -> $verdict, $ntests test(s)"
  else
    echo "  -> NESSUN ZMIOUT (controllare il log in $LOGDIR/regen_${name}.log)"
  fi
done
echo "REGEN_ALL_DONE"
