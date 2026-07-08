#!/bin/bash
# Batch re-test 12Jun — verifica fix external entry point
# Ogni contratto: step1+2, genera aux.pl (external), step3+4, analisi

set -euo pipefail

BASE="/home/labeconomia/mdiianni/verimap_projects/swipl_z3_clpq_interpreter"
SCRIPT="$BASE/script"
LOG="$BASE/test/batch_12Jun.log"

> "$LOG"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

gen_aux() {
    local pl_path="$1"
    local hint="$2"
    python3 - "$pl_path" "$hint" << 'PYEOF'
import sys
sys.path.insert(0, '/home/labeconomia/mdiianni/verimap_projects/swipl_z3_clpq_interpreter/script')
from sol2tpl import parse_fun_declarations, choose_function, generate_aux_pl
import os
pl_path = sys.argv[1]
hint    = sys.argv[2] if (len(sys.argv) > 2 and sys.argv[2]) else None
funs    = parse_fun_declarations(pl_path)
fun     = choose_function(funs, hint)
aux     = os.path.splitext(pl_path)[0] + '.aux.pl'
sol     = os.path.splitext(pl_path)[0] + '.sol'
generate_aux_pl(aux, fun, sol)
ext = fun.get('external')
print(f"  fun: {fun['name']}")
print(f"  ext: {ext['name'] if ext else 'NESSUNO (usa interno)'}")
PYEOF
}

run_test() {
    local tag="$1"
    local sol_name="$2"
    local hint="$3"
    local DIR="$BASE/test/12Jun_$tag"
    local SOL="$DIR/$sol_name"
    local BASE_NAME="${sol_name%.sol}"

    log "████ START: $tag ████"

    # Step 1: grey
    bash "$SCRIPT/step1_grey.sh" "$SOL" >> "$LOG" 2>&1

    # Step 2: yul2chc
    bash "$SCRIPT/step2_yul2chc.sh" "$DIR/$BASE_NAME.json" >> "$LOG" 2>&1

    # Genera aux.pl (con external se disponibile)
    log "  Genero aux.pl (hint='$hint')..."
    gen_aux "$DIR/$BASE_NAME.pl" "$hint" 2>&1 | tee -a "$LOG"

    # Step 3: transform
    bash "$SCRIPT/step3_transform.sh" "$DIR/$BASE_NAME.pl" >> "$LOG" 2>&1

    # Step 4: constr
    bash "$SCRIPT/step4_constr.sh" "$DIR/$BASE_NAME.t.pl" >> "$LOG" 2>&1

    # Analisi
    log "  Lancio analisi..."
    bash "$SCRIPT/InterpreterAnalysis5.2.sh" \
        --stop-first-per-loop --timeout 300 \
        "$DIR/$BASE_NAME.t_constr.pl" incorrect >> "$LOG" 2>&1

    # Step 6: vars z3
    ZMIOUT=$(ls -t "$DIR"/*.zmiout 2>/dev/null | head -1 || true)
    if [ -n "$ZMIOUT" ]; then
        DEFS="$DIR/$BASE_NAME.t.pl-defs.txt"
        bash "$SCRIPT/step6_vars.sh" --z3 "$SOL" "$DEFS" "$ZMIOUT" >> "$LOG" 2>&1 || true
    fi

    # Step 8: annotate
    bash "$SCRIPT/step8_annotate.sh" "$SOL" >> "$LOG" 2>&1 || true

    # Risultato
    RESULT=$(ls "$DIR"/*.zmiout 2>/dev/null | head -1 | xargs -I{} basename {} || echo "NESSUN ZMIOUT")
    log "  RISULTATO: $RESULT"
    log "████ DONE: $tag ████"
    echo "" >> "$LOG"
}

log "=== BATCH 12Jun AVVIATO ==="
log ""

# Formato: run_test <tag> <sol_file> <function_hint>
run_test "simple_if_correct"   "simple_if.sol"         "simple_if"
run_test "simple_if_buggy"     "simple_if_buggy.sol"   "simple_if"
run_test "simple_if_2_buggy"   "simple_if_2_buggy.sol" "simple_if_2"
run_test "for1fail"            "for_1_fail.sol"         "f"
run_test "for1correct"         "for_1_correct.sol"      "f"
run_test "loop_if"             "loop_if.sol"            "loop_if"
run_test "few_calls"           "few_calls.sol"          "f"
run_test "many_fun"            "many_fun.sol"           "f5"
run_test "overloading"         "overloading.sol"        "f_30"
run_test "seq_calls"           "seq_calls.sol"          "call_1"
run_test "simple_if_2"         "simple_if_2.sol"        "simple_if_2"
run_test "state_machine_1"     "state_machine_1.sol"    "i"

log ""
log "=== BATCH COMPLETATO ==="
log ""
log "=== RIEPILOGO RISULTATI ==="
for d in "$BASE/test/12Jun_"*; do
    tag=$(basename "$d" | sed 's/12Jun_//')
    zmiout=$(ls "$d"/*.zmiout 2>/dev/null | head -1 | xargs -I{} basename {} || echo "ERRORE/NESSUNO")
    log "  $tag: $zmiout"
done
