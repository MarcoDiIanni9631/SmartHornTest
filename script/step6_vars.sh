#!/bin/bash
# step6_vars.sh [--z3] [--clpq] <contract.sol> <contract.t.pl-defs.txt> <contract.*.zmiout>
# Mappa le variabili Z3 ai nomi Solidity. Produce .vars_z3.txt e/o .vars_clpq.txt.
# Default: --z3 (se non specificato nessun backend)
#
# Esempio:
#   bash script/step6_vars.sh --z3 test/MyContract/MyContract.sol \
#     test/MyContract/MyContract.t.pl-defs.txt \
#     test/MyContract/MyContract.t_constr.pl.*.zmiout

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ZMIOUT2VARS_Z3="$SCRIPT_DIR/zmiout2vars_z3.py"
ZMIOUT2VARS_CLPQ="$SCRIPT_DIR/zmiout2vars_clpq.py"

DO_Z3=false
DO_CLPQ=false
POSITIONAL=()

while [ $# -gt 0 ]; do
  case "$1" in
    --z3)   DO_Z3=true;  shift ;;
    --clpq) DO_CLPQ=true; shift ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

# default: z3
if ! $DO_Z3 && ! $DO_CLPQ; then DO_Z3=true; fi

[ "${#POSITIONAL[@]}" -lt 3 ] && {
  echo "Uso: $0 [--z3] [--clpq] <contract.sol> <contract.t.pl-defs.txt> <contract.*.zmiout>"
  exit 1
}

SOL="${POSITIONAL[0]}"
DEFS="${POSITIONAL[1]}"
ZMIOUT="${POSITIONAL[2]}"

echo "=== STEP 6: vars → .vars.txt ==="

if $DO_Z3; then
  echo "[Z3]"
  python3 "$ZMIOUT2VARS_Z3" "$SOL" "$DEFS" "$ZMIOUT"
fi

if $DO_CLPQ; then
  echo "[CLPQ]"
  python3 "$ZMIOUT2VARS_CLPQ" "$SOL" "$DEFS" "$ZMIOUT"
fi
