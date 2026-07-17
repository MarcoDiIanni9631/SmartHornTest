#!/bin/bash
#
# ==========================================================
# Script: InterpreterAnalysis5.1.sh
# Autore: Marco Di Ianni
# Descrizione:
#   Analizza file .pl con l’interprete Prolog.
#   Supporta automaticamente file .c associati (se presenti).
#   Opzioni: --skip-existing, --stop-first, --stop-first-per-loop, ecc.
# ==========================================================

set -u

# Salva la riga di comando originale prima del parsing
ORIG_CMDLINE="$*"

# ----------------------------------------------------------
# PARSING ARGOMENTI (flag e posizionali in qualsiasi ordine)
# ----------------------------------------------------------

DEBUG="no"
SKIP_EXISTING="no"
MAXDEPTH=""
LOOPLIMIT=""
TIMEOUT_OVERRIDE=""
SKIP_FILE=""
STOP_FIRST="no"
STOP_PER_LOOP="no"
INPUT_PATH=""
TARGET=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --debug)         DEBUG="yes";              shift ;;
    --skip-existing) SKIP_EXISTING="yes";      shift ;;
    --maxdepth)      MAXDEPTH="$2";            shift 2 ;;
    --looplimit)     LOOPLIMIT="$2";           shift 2 ;;
    --timeout)       TIMEOUT_OVERRIDE="$2";    shift 2 ;;
    --skip-file)     SKIP_FILE="$2";           shift 2 ;;
    --stop-first)          STOP_FIRST="yes";          shift ;;
    --stop-first-per-loop) STOP_PER_LOOP="yes";       shift ;;
    *)
      if [ -z "$INPUT_PATH" ]; then
        INPUT_PATH="$1"
      elif [ -z "$TARGET" ]; then
        TARGET="$1"
      else
        echo "❌ Argomento inaspettato: $1"
        exit 1
      fi
      shift ;;
  esac
done

MAXDEPTH="${MAXDEPTH:-10000000}"

# ----------------------------------------------------------
# CONTROLLO ARGOMENTI OBBLIGATORI
# ----------------------------------------------------------
if [ -z "$INPUT_PATH" ] || [ -z "$TARGET" ]; then
  echo "Uso:"
  echo "  nohup $0 [--debug] [--stop-first] [--stop-first-per-loop] [--skip-existing] [--maxdepth N] [--looplimit N] [--timeout SEC] [--skip-file F] <file_o_cartella> <predicato> &"
  exit 1
fi

# Percorso assoluto di questo script → usato per trovare main.pl e i tool
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
MAIN="$SCRIPT_DIR/../src/core/main.pl"

# ----------------------------------------------------------
# CONTROLLI DI BASE
# ----------------------------------------------------------
if [ ! -e "$INPUT_PATH" ]; then
  echo "❌ File o cartella non trovati: $INPUT_PATH"
  exit 1
fi

if [ ! -f "$MAIN" ]; then
  echo "❌ main.pl non trovato: $MAIN"
  exit 1
fi

# ----------------------------------------------------------
# CONFIGURAZIONE AMBIENTE
# Path presi da config.sh (override via variabili d'ambiente:
# GREY_DIR, YULCHC_DIR, SWIPL_BIN, SWIZ3_TURIBE_PATH, Z3_LIB_DIR).
# ----------------------------------------------------------
source "$SCRIPT_DIR/config.sh"

export LD_LIBRARY_PATH="${Z3_LIB_DIR:+$Z3_LIB_DIR:}${SWIZ3_TURIBE_PATH}:${SWIZ3_TURIBE_PATH}/z3/build:${LD_LIBRARY_PATH:-}"
TIMEOUT_SEC=60000

if [ -z "$SWIPL_BIN" ] || [ ! -x "$SWIPL_BIN" ]; then
  echo "❌ SWI-Prolog not found (SWIPL_BIN='$SWIPL_BIN'). Set it with: export SWIPL_BIN=/path/to/swipl"
  exit 1
fi

[ -n "$TIMEOUT_OVERRIDE" ] && TIMEOUT_SEC="$TIMEOUT_OVERRIDE"

# # ----------------------------------------------------------
# # TROVA FILE C ASSOCIATO
# # ----------------------------------------------------------
# find_associated_c_file() {
#   local plfile="$1"
#   local dir base cfile

#   dir="$(dirname "$plfile")"
#   base="$(basename "$plfile")"

#   # Caso smt2map:
#   # foo.c.transform.smt.smt2.pl → foo.c
#   if [[ "$base" == *.c.transform.smt.smt2.pl ]]; then
#     cfile="$dir/${base%.transform.smt.smt2.pl}"
#     [ -f "$cfile" ] && echo "$cfile" && return
#   fi

#   # Fallback: foo.smt2.pl → foo.c
#   cfile="$dir/${base%.smt2.pl}.c"
#   [ -f "$cfile" ] && echo "$cfile" && return

#   echo ""
# }

# # ----------------------------------------------------------
# # ESECUZIONE PROLOG (CON / SENZA C)
# # ----------------------------------------------------------
# run_prolog() {
#   local plfile="$1"
#   local cfile

#   cfile="$(find_associated_c_file "$plfile")"

#   if [ -n "$cfile" ]; then
#     echo "📎 File C associato trovato: $(basename "$cfile")"
#     timeout ${TIMEOUT_SEC}s "$SWIPL_BIN" --stack-limit=4GB \
#       -s "$MAIN_ABS" -- \
#       "$cfile" "$plfile" "$TARGET"
#   else
#     timeout ${TIMEOUT_SEC}s "$SWIPL_BIN" --stack-limit=4GB \
#       -s "$MAIN_ABS" -- \
#       "$plfile" "$TARGET"
#   fi
# }


# ----------------------------------------------------------
# ESECUZIONE PROLOG (SOLO PL)
# ----------------------------------------------------------
run_prolog() {
  local plfile="$1"
  local extra_args=()
  [ "$DEBUG" = "yes" ]            && extra_args+=("--debug")
  [ "$STOP_FIRST" = "yes" ]       && extra_args+=("--stop-first")
  [ "$STOP_PER_LOOP" = "yes" ]    && extra_args+=("--stop-first-per-loop")
  extra_args+=("$plfile" "$TARGET")
  extra_args+=("--maxdepth" "$MAXDEPTH")
  [ -n "$LOOPLIMIT" ]        && extra_args+=("--looplimit" "$LOOPLIMIT")
  [ -n "$SKIP_FILE" ]        && extra_args+=("--skip-file" "$SKIP_FILE")

  timeout ${TIMEOUT_SEC}s "$SWIPL_BIN" --stack-limit=4GB \
    -s "$MAIN_ABS" -- \
    "${extra_args[@]}"
}


# ----------------------------------------------------------
# PROCESSAMENTO SINGOLO FILE
# ----------------------------------------------------------
process_file() {
  local file="$1"

  FILE_ABS="$(readlink -f "$file")"
  [ -f "$FILE_ABS" ] || return

  local dir filename base_no_ext tmpout
  dir="$(dirname "$FILE_ABS")"
  filename="$(basename "$FILE_ABS")"
  base_no_ext="$filename"
  tmpout="$dir/${base_no_ext}.tmpout"

  echo "🔎 Analizzo ora: $filename"

  if [ "$SKIP_EXISTING" = "yes" ]; then
    if compgen -G "$dir/${base_no_ext}".*.zmiout > /dev/null; then
      echo "⏭️  Skip: $filename (zmiout già presente)"
      return
    fi
  fi

  MAIN_ABS="$(readlink -f "$MAIN")"
  MAIN_DIR="$(dirname "$MAIN_ABS")"

  echo "▶️ File: $filename (timeout ${TIMEOUT_SEC}s)"
  echo "📂 Working dir: $MAIN_DIR"

  FILE_START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
  FILE_START_EPOCH="$(date +%s)"
  echo "=== ANALISI: $filename ===" > "$tmpout"
  echo "Comando:     bash InterpreterAnalysis5.2.sh $ORIG_CMDLINE" >> "$tmpout"
  echo "Inizio:      $FILE_START_TS" >> "$tmpout"
  echo "--- Parametri ---" >> "$tmpout"
  echo "MaxDepth:    $MAXDEPTH" >> "$tmpout"
  echo "LoopLimit:   ${LOOPLIMIT:-default}" >> "$tmpout"
  echo "Timeout:     ${TIMEOUT_SEC}s" >> "$tmpout"
  echo "OnlyFirstTestGlobal: $STOP_FIRST" >> "$tmpout"
  echo "OnlyFirstPerLoop: $STOP_PER_LOOP" >> "$tmpout"
  echo "Debug:            $DEBUG" >> "$tmpout"
  echo "SkipIfDone:       $SKIP_EXISTING" >> "$tmpout"
  [ -n "$SKIP_FILE" ] && echo "SkipFile:    $SKIP_FILE" >> "$tmpout"
  echo "-----------------" >> "$tmpout"
  echo "" >> "$tmpout"

  (
    cd "$MAIN_DIR" || exit 1
    run_prolog "$FILE_ABS"
  ) >> "$tmpout" 2>&1

  EXIT_CODE=$?

  FILE_END_TS="$(date '+%Y-%m-%d %H:%M:%S')"
  FILE_ELAPSED=$(( $(date +%s) - FILE_START_EPOCH ))
  FILE_ELAPSED_FMT="$(printf '%02dh %02dm %02ds' $((FILE_ELAPSED/3600)) $(((FILE_ELAPSED%3600)/60)) $((FILE_ELAPSED%60)))"
  echo "" >> "$tmpout"
  echo "Fine:   $FILE_END_TS" >> "$tmpout"
  echo "Durata: $FILE_ELAPSED_FMT" >> "$tmpout"

  # ----------------------------------------------------------
  # TAGGING OUTPUT (IDENTICO A 5.0)
  # ----------------------------------------------------------
  [ $EXIT_CODE -eq 124 ] && STATUS="timeout" || STATUS="NoTimeoutReached"

  TAG_MAXDEPTH="MaxDepth${MAXDEPTH}"

  TAG_LIMIT=$(grep -q "Limite MaxDepth raggiunto" "$tmpout" && echo "MaxDepthReached" || echo "MaxDepthNotReached")
  TAG_PUSH=$(grep -q "z3_push_failed" "$tmpout" && echo "Z3PushFailed" || echo "Z3PushOK")
  TAG_TERM=$(grep -q "Ho raggiunto la terminazione dell'albero" "$tmpout" && echo "totalExplored" || echo "notFullyExplored")
  TAG_ERROR=$(grep -Eqi "error|failed" "$tmpout" && echo "Error" || echo "NoError")

  error_type="NoTypeError"
  if grep -qiE "ERROR:|Type error" "$tmpout"; then
    raw_error=$(grep -im1 -E "ERROR:|Type error" "$tmpout")
    if echo "$raw_error" | grep -q "Type error"; then
      error_type="TypeError"
    else
      error_type="OtherError"
    fi
  fi

  if grep -qE "SAT MODEL|INCORRECT|FF FOUND" "$tmpout"; then
    analysis="derivable"
  else
    analysis="nonDerivable"
  fi

  finalout="$dir/${base_no_ext}.${STATUS}.${analysis}.${TAG_MAXDEPTH}.${TAG_LIMIT}.${TAG_PUSH}.${TAG_TERM}.${TAG_ERROR}.${error_type}.zmiout"
  mv "$tmpout" "$finalout" 2>/dev/null || true

  echo "✅ Output --> $finalout"
}

export -f process_file
export -f run_prolog
export MAIN SWIPL_BIN TIMEOUT_SEC TARGET SKIP_EXISTING MAXDEPTH LOOPLIMIT SKIP_FILE STOP_FIRST STOP_PER_LOOP ORIG_CMDLINE DEBUG

# ----------------------------------------------------------
# ESECUZIONE
# ----------------------------------------------------------
START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
START_EPOCH="$(date +%s)"
echo "🕐 Inizio analisi: $START_TS"
echo "==========================================="

if [ -d "$INPUT_PATH" ]; then
  echo "⚙️ Esecuzione parallela su: $INPUT_PATH"
  find "$INPUT_PATH" -type f -name "*.pl" -exec readlink -f {} \; \
    | parallel -j 16 process_file {}
else
  process_file "$(readlink -f "$INPUT_PATH")"
fi

END_TS="$(date '+%Y-%m-%d %H:%M:%S')"
END_EPOCH="$(date +%s)"
ELAPSED=$(( END_EPOCH - START_EPOCH ))
ELAPSED_FMT="$(printf '%02dh %02dm %02ds' $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60)))"

echo "==========================================="
echo "✅ Analisi completata!"
echo "🕐 Inizio:  $START_TS"
echo "🕑 Fine:    $END_TS"
echo "⏱️  Durata:  $ELAPSED_FMT"
echo "==========================================="
