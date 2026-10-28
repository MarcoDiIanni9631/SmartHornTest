#!/bin/bash
# Lancia un'analisi su un .sol (strada Yul o SolCMC) o su un .pl (solo interprete).
# Parte da sola in background. Aiuto: smarthorntest -h
aiuto() { cat <<'H'
USO
  smarthorntest <file.sol | file.pl | cartella> [opzioni]

  Con una cartella analizza uno dopo l'altro tutti i .sol che contiene (ognuno
  nella sua sottocartella), poi genera i test Foundry e lancia forge test.

  I parametri di default stanno in smarthorntest.conf (cartella del progetto):
  modifica quel file. Le opzioni qui sotto valgono solo per un lancio.

  Parte in background. Risultati e run.log finiscono nella cartella del file.

OPZIONI (tutte facoltative)
  -r STRADA    yul (default) o solcmc (solo .sol)
  -f NOME      funzione da analizzare (solo .sol, strada yul; se manca: la prima del contratto;
               con solcmc si analizzano tutti gli assert del contratto)
  -p PRED      predicato di partenza (solo .pl; se manca lo capisce da solo:
               incorrect se il file viene da Yul, ff se viene da SolCMC)
  -t SECONDI   timeout
  -d N         maxdepth, numero massimo di passi di risoluzione
  -l           --stop-first-per-loop (un solo test per ciclo)
  -s           --stop-first (si ferma al primo test)
  -v           solo con una cartella: aggiunge l'assert vgood a ogni contratto, cosi'
               escono anche i test positivi; Foundry gira sui contratti originali

ESEMPI
  smarthorntest test3/RewardPoints2.sol
  smarthorntest test3/RewardPoints2.sol -f claimRewards -t 60
  smarthorntest test3/RewardPoints2.sol -r solcmc -t 600
  smarthorntest test3/RewardPoints2.sol -l -d 400
  smarthorntest test3/RewardPoints2.t_constr.pl
  smarthorntest cartella/Contratto.chc.pl -p ff -t 600
  smarthorntest cartella/ -r solcmc -t 600

DOPO
  tail -5 <cartella>/run.log              e' finita? (cerca "Pipeline complete" / "Duration")
  grep -c 'TEST #' <cartella>/*.zmiout    quanti test
  cat <cartella>/*.test_cases.json        valori trovati (solo per .sol)
  con -r solcmc i risultati stanno in <cartella>/solcmc/<nome>/
  con una cartella: <cartella>/run.log, <cartella>/forge_test.txt e <cartella>/report.csv
  (il report si rifa' su qualsiasi cartella con: python3 script/report.py <cartella>)
H
}
[ "$1" = -h ] || [ "$1" = --help ] || [ -z "$1" ] && { aiuto; exit 0; }
[ -e "$1" ] || { echo "File non trovato: $1   (aiuto: smarthorntest -h)"; exit 1; }
FILE=$(readlink -f "$1"); shift; D=$(dirname "$FILE"); R=$(cd "$(dirname "$0")" && pwd)
TIMEOUT=1200; MAXDEPTH=; PER_LOOP=no; STOP_FIRST=no; FUNZIONE=; PREDICATO=
[ -f "$R/smarthorntest.conf" ] && source "$R/smarthorntest.conf"
F=$FUNZIONE; P=$PREDICATO; T=$TIMEOUT; S=yul; V=no; EXTRA=()
[ -n "$MAXDEPTH" ] && EXTRA+=(--maxdepth "$MAXDEPTH")
[ "$PER_LOOP" = si ] && EXTRA+=(--stop-first-per-loop)
[ "$STOP_FIRST" = si ] && EXTRA+=(--stop-first)
while getopts "r:f:p:t:d:lsv" o; do case $o in
  r) S=$OPTARG ;; f) F=$OPTARG ;; p) P=$OPTARG ;; t) T=$OPTARG ;; d) EXTRA+=(--maxdepth "$OPTARG") ;;
  l) EXTRA+=(--stop-first-per-loop) ;; s) EXTRA+=(--stop-first) ;; v) V=si ;;
  *) echo "Opzione sconosciuta (aiuto: smarthorntest -h)"; exit 1 ;; esac; done
echo "Parametri: timeout $T s ${EXTRA[*]:-(nessuna altra opzione)}"
[ "$S" = yul ] || [ "$S" = solcmc ] || { echo "Strada sconosciuta: $S (yul o solcmc)"; exit 1; }
if [ -d "$FILE" ]; then
  SOLS=("$FILE"/*.sol)
  [ -f "${SOLS[0]}" ] || { echo "Nessun .sol in $FILE"; exit 1; }
  (
    trap '' HUP
    for s in "${SOLS[@]}"; do
      n=$(basename "$s" .sol); mkdir -p "$FILE/$n"
      if [ $V = si ]; then python3 "$R/script/add_vgood.py" "$s" "$FILE/$n/$n.sol"; else cp "$s" "$FILE/$n/"; fi
      echo "$(date +%H:%M) $n"
      if [ "$S" = solcmc ]; then
        mkdir -p "$FILE/$n/solcmc"
        (cd "$R" && bash script/solcmc_route.sh "$FILE/$n/$n.sol" --timeout "$T" "${EXTRA[@]}") > "$FILE/$n/solcmc/run.log" 2>&1
      else
        f=${F:-$(grep -oP 'function\s+\K\w+' "$s" | head -1)}
        (cd "$R" && flock "$R/.yul.lock" bash script/sol2analysis.sh --gen-aux --aux-hint "_${f}_" --varz3 --varclpq \
          --timeout "$T" "${EXTRA[@]}" "$FILE/$n/$n.sol" incorrect) > "$FILE/$n/run.log" 2>&1
      fi
    done
    rm -rf "$FILE/foundry"
    python3 "$R/script/witnesses2foundry.py" --forge-std "$FILE/foundry" "$FILE"
    # con -v i test girano sul contratto originale: positivo confermato = PASS
    if [ $V = si ]; then
      for b in "$FILE"/foundry/src/*.sol; do
        o=$FILE/${b##*__}; [ -f "$o" ] && cp "$o" "$b"
      done
    fi
    (cd "$FILE/foundry" && forge test) > "$FILE/forge_test.txt" 2>&1
    python3 "$R/script/report.py" "$FILE"
    echo "$(date +%H:%M) Pipeline complete, report in $FILE/report.csv"
  ) > "$FILE/run.log" 2>&1 < /dev/null &
  echo "Partita su ${#SOLS[@]} contratti in $FILE (strada $S, timeout $T s). Log: $FILE/run.log"
  exit 0
fi
case $FILE in
  *.sol) if [ "$S" = solcmc ]; then
           mkdir -p "$D/solcmc"
           cd "$R" && nohup bash script/solcmc_route.sh "$FILE" --timeout "$T" "${EXTRA[@]}" > "$D/solcmc/run.log" 2>&1 &
           echo "Partita su $FILE (strada SolCMC, timeout $T s). Log: $D/solcmc/run.log"; exit 0
         fi
         F=${F:-$(grep -oP 'function\s+\K\w+' "$FILE" | head -1)}
         # un'analisi yul2chc alla volta: la conversione usa la cartella condivisa grey/
         cd "$R" && nohup flock "$R/.yul.lock" bash script/sol2analysis.sh --gen-aux --aux-hint "_${F}_" --varz3 --varclpq \
           --timeout "$T" "${EXTRA[@]}" "$FILE" incorrect > "$D/run.log" 2>&1 &
         echo "Partita su $FILE (funzione $F, timeout $T s). Log: $D/run.log" ;;
  *.pl)  if [ -z "$P" ]; then
           if grep -qE '^\s*incorrect\s*(:-|\.)' "$FILE"; then P=incorrect
           elif grep -qE '^\s*ff\s*(:-|\.)' "$FILE"; then P=ff
           else echo "Non trovo ne' incorrect ne' ff nel file: indica il predicato con -p"; exit 1; fi
         fi
         cd "$R/script" && nohup bash InterpreterAnalysis5.2.sh --timeout "$T" "${EXTRA[@]}" "$FILE" "$P" \
           > "$D/run.log" 2>&1 &
         echo "Partita su $FILE (predicato $P, timeout $T s). Log: $D/run.log" ;;
  *)     echo "Serve un .sol o un .pl" ; exit 1 ;;
esac
