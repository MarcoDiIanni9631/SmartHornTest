#!/bin/bash
# Strada SolCMC su un contratto: _solcmc_uno.sh SORGENTE.sol CARTELLA_OUT
# solc (query CHC) -> solcmc_assume_asserts.py -> smt2map -> smt2pl_to_constr.pl --single-tx
# -> interprete (looplimit 10, timeout 60 s; si cambiano con LOOPLIMIT=, TIMEOUT=) -> solcmc_zmiout2json.py
# works on the laptop and on the server: paths from where the script is
R=$(cd "$(dirname "$0")/.." && pwd)
VERIMAP=${VERIMAP:-$(cd "$R/../verimap" && pwd)}
src=$1; d=$2; n=$(basename $d)
mkdir -p $d; cp $src $d/$n.sol
(cd $d && timeout 300 solc $n.sol --model-checker-engine chc --model-checker-solvers smtlib2 \
   --model-checker-print-query --model-checker-targets assert > solc_query.txt 2>&1)
awk '/Info: CHC: Requested query:/{buf=""; on=1; next} on{buf=buf $0 "\n"} /^\(check-sat\)/{if(on){last=buf; on=0}} END{printf "%s", last}' \
  $d/solc_query.txt > $d/${n}_solc.smt2
if [ ! -s $d/${n}_solc.smt2 ]; then echo "nessuna query da solc"; exit 0; fi
python3 $R/script/solcmc_assume_asserts.py $d/${n}_solc.smt2 $d/$n.smt2 > $d/assume.log 2>&1
(cd $VERIMAP && timeout 300 ./scripts/smt2map $d/$n.smt2 > $d/smt2map.log 2>&1)
[ -s $d/$n.smt2.pl ] || { echo "smt2map non riuscito"; exit 0; }
timeout 300 swipl -q -g main -t halt $R/script/smt2pl_to_constr.pl -- --single-tx $d/$n.smt2.pl $d/$n.chc.pl > $d/convert.log 2>&1
[ -s $d/$n.chc.pl ] || { echo "conversione non riuscita"; exit 0; }
rm -f $d/*.zmiout
(cd $R/script && SKIP_STEP4B=1 timeout 400 bash InterpreterAnalysis5.2.sh --looplimit ${LOOPLIMIT:-10} --timeout ${TIMEOUT:-60} $d/$n.chc.pl ff > $d/interp.log 2>&1)
z=$(ls $d/*.zmiout 2>/dev/null | head -1)
[ -n "$z" ] && timeout 120 python3 $R/script/solcmc_zmiout2json.py $d > $d/json.log 2>&1
echo "$(basename "$z" | sed 's/.*chc.pl.//' | cut -d. -f1-2), $(grep -c 'TEST #' "$z" 2>/dev/null) test"
