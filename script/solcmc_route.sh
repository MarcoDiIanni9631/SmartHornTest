#!/bin/bash
# SolCMC route on one contract:
#   solc (CHC query) -> solcmc_assume_asserts.py -> smt2map -> smt2pl_to_constr.pl --single-tx
#   -> interpreter (target ff) -> solcmc_zmiout2json.py
# Usage: solcmc_route.sh FILE.sol [interpreter options, e.g. --timeout 600 --maxdepth 100]
# Results in solcmc/NAME/ next to FILE.sol (solcmc_zmiout2json.py wants the folder
# named like the contract): NAME.chc.pl, the .zmiout and NAME.test_cases.json.
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
VERIMAP=${VERIMAP:-$(cd "$R/../verimap" && pwd)}
FILE=$(readlink -f "$1"); shift
n=$(basename "$FILE" .sol); d=$(dirname "$FILE")/solcmc/$n
mkdir -p "$d"; cp "$FILE" "$d/$n.sol"
echo "SolCMC route on $FILE, results in $d"
(cd "$d" && timeout 300 solc "$n.sol" --model-checker-engine chc --model-checker-solvers smtlib2 --model-checker-print-query --model-checker-targets assert > solc_query.txt 2>&1)
# solc prints one query per target: the last one has all the rules
awk '/Info: CHC: Requested query:/{buf=""; on=1; next} on{buf=buf $0 "\n"} /^\(check-sat\)/{if(on){last=buf; on=0}} END{printf "%s", last}' \
  "$d/solc_query.txt" > "$d/${n}_solc.smt2"
[ -s "$d/${n}_solc.smt2" ] || { echo "no query from solc (see $d/solc_query.txt)"; exit 1; }
python3 "$R/script/solcmc_assume_asserts.py" "$d/${n}_solc.smt2" "$d/$n.smt2" > "$d/assume.log" 2>&1
(cd "$VERIMAP" && timeout 300 ./scripts/smt2map "$d/$n.smt2" > "$d/smt2map.log" 2>&1)
[ -s "$d/$n.smt2.pl" ] || { echo "smt2map failed (see $d/smt2map.log)"; exit 1; }
timeout 300 swipl -q -g main -t halt "$R/script/smt2pl_to_constr.pl" -- --single-tx "$d/$n.smt2.pl" "$d/$n.chc.pl" > "$d/convert.log" 2>&1
[ -s "$d/$n.chc.pl" ] || { echo "conversion failed (see $d/convert.log)"; exit 1; }
rm -f "$d/$n.chc.pl".*.zmiout "$d"/target_*/*.zmiout
# one analysis per assert (error target), in parallel, as SolCMC checks each
# assert on its own: an assert that cannot fail then only uses up its own
# timeout, and does not hide the asserts the search would reach after it
targets=$(sed -n 's/^ff :- constr(true), \(error_target_[0-9]*\)\.$/\1/p' "$d/$n.chc.pl")
for t in $targets; do
  mkdir -p "$d/target_${t#error_target_}"
  { grep -v '^ff :- ' "$d/$n.chc.pl"; echo "ff :- constr(true), $t."; } > "$d/target_${t#error_target_}/$n.chc.pl"
  (cd "$R/script" && bash InterpreterAnalysis5.2.sh "$@" "$d/target_${t#error_target_}/$n.chc.pl" ff) > "$d/target_${t#error_target_}/run.log" 2>&1 &
done
wait
zs=$(ls "$d"/target_*/"$n.chc.pl".*.zmiout 2>/dev/null)
[ -n "$zs" ] || { echo "no .zmiout from the interpreter"; exit 1; }
# one .zmiout for the contract: the tests of every target, and the outcome
# tags of the worst one (timeout, error, not fully explored) or derivable if
# any target has a test
tags=$(for z in $zs; do basename "$z" | sed "s/^$n\.chc\.pl\.//; s/\.zmiout$//"; done | python3 -c '
import sys
rows = [l.strip().split(".") for l in sys.stdin if l.strip()]
# the tags that say nothing went wrong: if a target has another one, keep that
fine = {"NoTimeoutReached", "nonDerivable", "MaxDepthNotReached", "totalExplored",
        "Z3PushOK", "NoError", "NoTypeError"}
out = []
for col in zip(*rows):
    other = [c for c in col if c not in fine]
    out.append(other[0] if other else col[0])
print(".".join(out))')
z="$d/$n.chc.pl.$tags.zmiout"
cat $zs > "$z"
timeout 120 python3 "$R/script/solcmc_zmiout2json.py" "$d" > "$d/json.log" 2>&1
echo "Pipeline complete: $(basename "$z" | sed 's/.*chc.pl.//' | cut -d. -f1-2), $(grep -c 'TEST #' "$z") test, json in $d/$n.test_cases.json"
