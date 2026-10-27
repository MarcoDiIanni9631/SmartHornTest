#!/bin/bash
# Lancia un'analisi su un .sol (strada Yul o SolCMC) o su un .pl (solo interprete).
# Parte da sola in background. Aiuto: smarthorntest -h
aiuto() { cat <<'H'
USO
  smarthorntest <file.sol | file.pl> [opzioni]

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

ESEMPI
  smarthorntest test3/RewardPoints2.sol
  smarthorntest test3/RewardPoints2.sol -f claimRewards -t 60
  smarthorntest test3/RewardPoints2.sol -r solcmc -t 600
  smarthorntest test3/RewardPoints2.sol -l -d 400
  smarthorntest test3/RewardPoints2.t_constr.pl
  smarthorntest cartella/Contratto.chc.pl -p ff -t 600

DOPO
  tail -5 <cartella>/run.log              e' finita? (cerca "Pipeline complete" / "Duration")
  grep -c 'TEST #' <cartella>/*.zmiout    quanti test
  cat <cartella>/*.test_cases.json        valori trovati (solo per .sol)
  con -r solcmc i risultati stanno in <cartella>/solcmc/<nome>/
H
}
[ "$1" = -h ] || [ "$1" = --help ] || [ -z "$1" ] && { aiuto; exit 0; }
[ -f "$1" ] || { echo "File non trovato: $1   (aiuto: smarthorntest -h)"; exit 1; }
FILE=$(readlink -f "$1"); shift; D=$(dirname "$FILE"); R=$(cd "$(dirname "$0")" && pwd)
TIMEOUT=1200; MAXDEPTH=; PER_LOOP=no; STOP_FIRST=no; FUNZIONE=; PREDICATO=
[ -f "$R/smarthorntest.conf" ] && source "$R/smarthorntest.conf"
F=$FUNZIONE; P=$PREDICATO; T=$TIMEOUT; S=yul; EXTRA=()
[ -n "$MAXDEPTH" ] && EXTRA+=(--maxdepth "$MAXDEPTH")
[ "$PER_LOOP" = si ] && EXTRA+=(--stop-first-per-loop)
[ "$STOP_FIRST" = si ] && EXTRA+=(--stop-first)
while getopts "r:f:p:t:d:ls" o; do case $o in
  r) S=$OPTARG ;; f) F=$OPTARG ;; p) P=$OPTARG ;; t) T=$OPTARG ;; d) EXTRA+=(--maxdepth "$OPTARG") ;;
  l) EXTRA+=(--stop-first-per-loop) ;; s) EXTRA+=(--stop-first) ;;
  *) echo "Opzione sconosciuta (aiuto: smarthorntest -h)"; exit 1 ;; esac; done
echo "Parametri: timeout $T s ${EXTRA[*]:-(nessuna altra opzione)}"
[ "$S" = yul ] || [ "$S" = solcmc ] || { echo "Strada sconosciuta: $S (yul o solcmc)"; exit 1; }
case $FILE in
  *.sol) if [ "$S" = solcmc ]; then
           mkdir -p "$D/solcmc"
           cd "$R" && nohup bash script/solcmc_route.sh "$FILE" --timeout "$T" "${EXTRA[@]}" > "$D/solcmc/run.log" 2>&1 &
           echo "Partita su $FILE (strada SolCMC, timeout $T s). Log: $D/solcmc/run.log"; exit 0
         fi
         F=${F:-$(grep -oP 'function\s+\K\w+' "$FILE" | head -1)}
         cd "$R" && nohup bash script/sol2analysis.sh --gen-aux --aux-hint "_${F}_" --varz3 --varclpq \
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
