#!/bin/bash
# Tutto il processo su un .sol, un passo dopo l'altro, a schermo.
# Aiuto: smarthorntest-completo -h
aiuto() { cat <<'H'
USO
  smarthorntest-completo <file.sol> [opzioni]

  Fa tutti i passi, in ordine, e scrive tutto in <cartella del file>/<nome>_completo/
    1. aggiunge il marcatore vgood (cosi' escono anche i test positivi)
    2. strada yul2chc: Solidity -> Yul -> CHC -> meta-interprete -> test (json)
    3. strada SolCMC:  query CHC di solc -> meta-interprete -> test (json)
    4. Foundry: ogni test diventa un test Foundry e gira sul contratto ORIGINALE
         negativo confermato = l'assert vero si rompe davvero (Panic 0x01)
         positivo confermato = la chiamata passa senza errori
    5. coverage dei test generati (forge coverage)
  maxdepth e timeout vengono da smarthorntest.conf (come smarthorntest).

OPZIONI (tutte facoltative)
  -f NOME      funzione da analizzare sulla strada yul2chc (se manca: la prima)
  -t SECONDI   timeout del meta-interprete
  -d N         maxdepth
  -s STRADA    solo una strada: yul oppure solcmc (se manca: tutte e due)
  -n           niente vgood (solo test negativi)

ESEMPIO
  smarthorntest-completo provaCompleto21Ottobre/Bonus.sol -f addBonus

DOPO (cartella <nome>_completo/)
  comandi.txt          tutti i comandi lanciati, in ordine (si possono rilanciare uno a uno)
  originale/           il contratto come l'hai scritto
  <nome>.sol           il contratto con vgood (quello analizzato)
  yul/, solcmc/        risultati delle due strade (.zmiout, .test_cases.json, ...)
  foundry_yul/, foundry_solcmc/   progetti Foundry: test/*.t.sol, forge.json
  coverage_yul.txt, coverage_solcmc.txt
H
}
[ "$1" = -h ] || [ "$1" = --help ] || [ -z "$1" ] && { aiuto; exit 0; }
[ -f "$1" ] && [[ $1 == *.sol ]] || { echo "Serve un file .sol esistente: $1   (aiuto: smarthorntest-completo -h)"; exit 1; }
FILE=$(readlink -f "$1"); shift
R=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
export PATH=$HOME/bin:$HOME/.foundry/bin:$PATH
TIMEOUT=1200; MAXDEPTH=; FUNZIONE=
[ -f "$R/smarthorntest.conf" ] && source "$R/smarthorntest.conf"
F=$FUNZIONE; T=$TIMEOUT; M=$MAXDEPTH; STRADE="yul solcmc"; VGOOD=si
while getopts "f:t:d:s:n" o; do case $o in
  f) F=$OPTARG ;; t) T=$OPTARG ;; d) M=$OPTARG ;; s) STRADE=$OPTARG ;; n) VGOOD=no ;;
  *) echo "Opzione sconosciuta (aiuto: smarthorntest-completo -h)"; exit 1 ;; esac; done
N=$(basename "$FILE" .sol); O=$(dirname "$FILE")/${N}_completo
F=${F:-$(grep -oP 'function\s+\K\w+' "$FILE" | head -1)}
MD=${M:+--maxdepth $M}
C=$O/comandi.txt
passo() { echo; echo "=== $* ==="; printf '\n# === %s ===\n' "$*" >> $C; }
nota() { echo "# $*" >> $C; }
# scrive il comando in comandi.txt (una riga, si puo' copiare e rilanciare) e poi lo esegue
cmd() { echo "$1" >> $C; (eval "$1"); }
cmdq() { echo "$1" >> $C; (eval "$1") > /dev/null; }

echo "Contratto: $FILE"
echo "Parametri: funzione $F (strada yul2chc), timeout $T s, ${MD:-nessun maxdepth}, strade: $STRADE, vgood: $VGOOD"
echo "Risultati in: $O"
rm -rf "$O"; mkdir -p "$O/originale"; cp "$FILE" "$O/originale/$N.sol"
{ echo "# Comandi lanciati da smarthorntest-completo il $(date '+%d/%m/%Y %H:%M')"
  echo "# Contratto: $FILE"
  echo "# Parametri: funzione $F (strada yul2chc), timeout $T s, ${MD:-nessun maxdepth}, strade: $STRADE, vgood: $VGOOD"
  echo "# Ogni riga si puo' copiare e rilanciare da sola, nell'ordine."; } > $C

passo "1. marcatore vgood"
if [ $VGOOD = si ]; then cmd "python3 $R/script/add_vgood.py $FILE $O/$N.sol"; else cp "$FILE" "$O/$N.sol"; echo "saltato (-n)"; fi
solc --bin "$O/$N.sol" > /dev/null 2>&1 || { echo "Il contratto non compila con solc: mi fermo"; exit 1; }

for s in $STRADE; do
  d=$O/$s/$N; mkdir -p $d; cp "$O/$N.sol" $d/
  if [ $s = yul ]; then
    passo "2. strada yul2chc (funzione $F)"
    nota "2a. conversione: Solidity -> Yul -> CHC (.t_constr.pl)"
    cmd "cd $R && bash script/sol2analysis.sh --until-tpl --gen-aux --aux-hint _${F}_ $d/$N.sol > $d/_convert.log 2>&1"
    nota "2b. meta-interprete (target incorrect) + valori e vincoli (json)"
    cmd "cd $R && bash script/sol2analysis.sh --skip-convert $MD --varz3 --varclpq --timeout $T $d/$N.sol incorrect > $d/_analisi.log 2>&1"
  else
    passo "3. strada SolCMC (tutte le funzioni, una transazione)"
    nota "3a. solc scrive la query CHC (SMT-LIB)"
    cmd "cd $d && solc $N.sol --model-checker-engine chc --model-checker-solvers smtlib2 --model-checker-print-query --model-checker-targets assert > solc_query.txt 2>&1"
    awk '/Info: CHC: Requested query:/{buf=""; on=1; next} on{buf=buf $0 "\n"} /^\(check-sat\)/{if(on){last=buf; on=0}} END{printf "%s", last}' $d/solc_query.txt > $d/${N}_solc.smt2
    [ -s $d/${N}_solc.smt2 ] || { echo "nessuna query da solc"; continue; }
    nota "(lo script estrae l'ultima query da solc_query.txt in ${N}_solc.smt2)"
    nota "3b. gli assert diventano obiettivi da raggiungere"
    cmd "python3 $R/script/solcmc_assume_asserts.py $d/${N}_solc.smt2 $d/$N.smt2 > $d/assume.log 2>&1"
    nota "3c. SMT-LIB -> Prolog (smt2map di VeriMAP)"
    cmd "cd ${VERIMAP:-$(cd $R/../verimap && pwd)} && ./scripts/smt2map $d/$N.smt2 > $d/smt2map.log 2>&1"
    nota "3d. Prolog -> CHC per il meta-interprete (.chc.pl)"
    cmd "swipl -q -g main -t halt $R/script/smt2pl_to_constr.pl -- --single-tx $d/$N.smt2.pl $d/$N.chc.pl > $d/convert.log 2>&1"
    nota "3e. meta-interprete (target ff)"
    cmd "cd $R/script && bash InterpreterAnalysis5.2.sh $MD --timeout $T $d/$N.chc.pl ff > $d/interp.log 2>&1"
    nota "3f. valori e vincoli (json)"
    cmd "python3 $R/script/solcmc_zmiout2json.py $d > $d/json.log 2>&1"
  fi
  z=$(ls $d/*.zmiout 2>/dev/null | head -1)
  [ -z "$z" ] && { echo "nessun risultato del meta-interprete (log in $d)"; continue; }
  echo "esito: $(basename "$z" | grep -o 'NoTimeoutReached\|timeout' | head -1), $(basename "$z" | grep -o 'nonDerivable\|derivable' | head -1), $(basename "$z" | grep -o 'MaxDepthReached\|MaxDepthNotReached')"
  python3 - $d/$N.test_cases.json <<'P'
import json, sys
try: d = json.load(open(sys.argv[1]))
except (OSError, ValueError): sys.exit(print("nessun test"))
for f in d.get("functions", []):
    for t in f["test_cases"]:
        print(f"  {f['signature']:28} {t['kind']:9} {', '.join(t['concrete_values']) or '(nessun valore)'}")
P
done

for s in $STRADE; do
  ls $O/$s/$N/*.test_cases.json > /dev/null 2>&1 || continue
  passo "4. Foundry ($s): test eseguiti sul contratto originale"
  # src/ prende il contratto senza vgood: e' quello che si vuole controllare
  cmdq "python3 $R/script/witnesses2foundry.py --forge-std $O/foundry_$s $O/$s"
  [ -f $O/foundry_$s/src/${s}__$N.sol ] || { echo "nessun test Foundry (nessuna violazione trovata o funzione non gestita)"; continue; }
  cmd "cp $FILE $O/foundry_$s/src/${s}__$N.sol"
  cmd "cd $O/foundry_$s && forge test --offline --match-path 'test/*' --json > forge.json 2> forge.err"
  python3 - $O/foundry_$s/forge.json <<'P'
import json, sys
try: d = json.load(open(sys.argv[1]))
except (OSError, ValueError): sys.exit(print("forge non e' partito: guarda forge.err"))
ok = n = 0
for suite, v in d.items():
    for t, x in sorted(v["test_results"].items()):
        r = x.get("reason") or ""
        conf = ("assertion failed" in r) if "negative" in t else (x["status"] == "Success")
        n += 1; ok += conf
        print(f"  {t:22} {'confermato' if conf else 'NON confermato'}  ({'passa' if x['status'] == 'Success' else r})")
print(f"  confermati {ok} su {n}")
P
  echo "  file del test: $O/foundry_$s/test/${s}__$N.t.sol"

  passo "5. coverage ($s)"
  cmdq "python3 $R/script/witnesses2foundry.py --coverage $O/cov_$s $O/$s"
  cmd "cp $FILE $O/cov_$s/src/${s}__$N.sol"
  cmd "cd $O/cov_$s && forge coverage --offline --match-path 'test/*' --no-match-coverage 'test/' --report summary --report lcov > ../coverage_$s.txt 2>&1"
  grep -E "^\| (File|src/)" $O/coverage_$s.txt | sed 's/^/  /'
done
echo; echo "Fatto. Tutto in $O"; echo "Comandi lanciati: $C"
