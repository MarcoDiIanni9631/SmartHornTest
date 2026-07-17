#!/bin/bash
# install.sh — installa le dipendenze del pipeline SmartHornTest
# (grey, yul-chc, swi-prolog-z3, Z3) come cartelle sibling di questo repo,
# e compila il bridge SWI-Prolog/Z3.
#
# Uso:
#   bash script/install.sh
#
# Non richiede sudo/apt: se manca git, python3, swipl, swipl-ld, gcc,
# curl/wget o unzip, si ferma e indica cosa installare manualmente
# (utile su server condivisi senza permessi root).
#
# Override via variabili d'ambiente:
#   GREY_REPO_URL, YULCHC_REPO_URL, SWIZ3_REPO_URL   (default: i fork di MarcoDiIanni9631)
#   ARCHIVE_URL                                       (default: Z3 4.15.2 linux x64 glibc 2.39)
#   SKIP_Z3=1                                          (salta il download di Z3, usa Z3_LIB_DIR già impostata)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PROJECTS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREY_REPO_URL="${GREY_REPO_URL:-https://github.com/MarcoDiIanni9631/grey.git}"
YULCHC_REPO_URL="${YULCHC_REPO_URL:-https://github.com/MarcoDiIanni9631/yul-chc.git}"
SWIZ3_REPO_URL="${SWIZ3_REPO_URL:-https://github.com/MarcoDiIanni9631/swi-prolog-z3.git}"
ARCHIVE_URL="${ARCHIVE_URL:-https://github.com/Z3Prover/z3/releases/download/z3-4.15.2/z3-4.15.2-x64-glibc-2.39.zip}"
SKIP_Z3="${SKIP_Z3:-0}"

echo "=================================================="
echo "🔧 Installazione SmartHornTest in: $PROJECTS_ROOT"
echo "=================================================="

# ------------------------------------------------------------------
# 1. Controllo strumenti richiesti (nessuna installazione automatica)
# ------------------------------------------------------------------
missing=()
for cmd in git python3 swipl swipl-ld gcc unzip rsync; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  missing+=("curl o wget")
fi
if [ "${#missing[@]}" -gt 0 ]; then
  echo "❌ Strumenti mancanti: ${missing[*]}"
  echo "   Installali (es. 'sudo apt install swi-prolog build-essential unzip curl') e rilancia."
  exit 1
fi
echo "✅ Strumenti di base presenti (git, python3, swipl, swipl-ld, gcc, unzip, rsync)"

download() {
  # download <url> <dest>
  if command -v curl >/dev/null 2>&1; then
    curl -sL -o "$2" "$1"
  else
    wget -q -O "$2" "$1"
  fi
}

# ------------------------------------------------------------------
# 2. Clona grey, yul-chc, swi-prolog-z3 come sibling (salta se già presenti)
# ------------------------------------------------------------------
clone_if_missing() {
  local dir="$1" url="$2"
  if [ -d "$dir/.git" ]; then
    echo "⏭️  $(basename "$dir") già presente, salto il clone"
  else
    echo "⬇️  Clono $(basename "$dir")..."
    git clone --quiet "$url" "$dir"
  fi
}

clone_if_missing "$PROJECTS_ROOT/grey" "$GREY_REPO_URL"
clone_if_missing "$PROJECTS_ROOT/yul-chc" "$YULCHC_REPO_URL"
clone_if_missing "$PROJECTS_ROOT/swi-prolog-z3" "$SWIZ3_REPO_URL"
chmod +x "$PROJECTS_ROOT/grey/solc-latest"

# ------------------------------------------------------------------
# 3. Z3: scarica il binario precompilato (salta se già estratto o SKIP_Z3=1)
# ------------------------------------------------------------------
Z3_DIR="$PROJECTS_ROOT/z3"
if [ "$SKIP_Z3" = "1" ]; then
  echo "⏭️  SKIP_Z3=1: salto il download di Z3 (uso Z3_LIB_DIR/Z3_HOME già impostata)"
elif [ -f "$Z3_DIR/bin/libz3.so" ] && [ -f "$Z3_DIR/include/z3_api.h" ]; then
  echo "⏭️  Z3 già presente in $Z3_DIR, salto il download"
else
  echo "⬇️  Scarico Z3 da $ARCHIVE_URL"
  echo "   (se il tuo sistema non è linux x86_64/glibc, imposta ARCHIVE_URL con la release giusta"
  echo "    da https://github.com/Z3Prover/z3/releases prima di rilanciare)"
  TMPZIP="$(mktemp --suffix=.zip)"
  download "$ARCHIVE_URL" "$TMPZIP"
  TMPEXTRACT="$(mktemp -d)"
  unzip -q "$TMPZIP" -d "$TMPEXTRACT"
  rm -f "$TMPZIP"
  mkdir -p "$Z3_DIR"
  # appiattisce la sottocartella versionata (z3-X.Y.Z-.../{bin,include}) in $Z3_DIR
  SRC="$(find "$TMPEXTRACT" -maxdepth 1 -mindepth 1 -type d | head -1)"
  rsync -a "$SRC"/ "$Z3_DIR"/
  rm -rf "$TMPEXTRACT"
fi

# ------------------------------------------------------------------
# 4. Compila il bridge SWI-Prolog / Z3
# ------------------------------------------------------------------
echo "🔨 Compilo z3_swi_foreign.so..."
Z3_INCLUDE="${Z3_INCLUDE:-$Z3_DIR/include}"
Z3_LIBDIR="${Z3_LIB_DIR:-$Z3_DIR/bin}"
(
  cd "$PROJECTS_ROOT/swi-prolog-z3"
  swipl-ld -shared -o z3_swi_foreign.so z3_swi_foreign.c -I"$Z3_INCLUDE" -L"$Z3_LIBDIR" -lz3
)
echo "✅ Bridge compilato"

# ------------------------------------------------------------------
# 5. Self-test: il bridge si carica correttamente in SWI-Prolog?
# ------------------------------------------------------------------
echo "🧪 Verifico che il bridge carichi..."
BRIDGE_SO="$PROJECTS_ROOT/swi-prolog-z3/z3_swi_foreign.so"
LD_LIBRARY_PATH="$Z3_LIBDIR:$PROJECTS_ROOT/swi-prolog-z3:${LD_LIBRARY_PATH:-}" \
  swipl -q -g "load_foreign_library('$BRIDGE_SO'), writeln('BRIDGE OK'), halt" \
  -t "halt(1)" 2>&1

echo ""
echo "=================================================="
echo "✅ Installazione completata."
echo "   grey:          $PROJECTS_ROOT/grey"
echo "   yul-chc:       $PROJECTS_ROOT/yul-chc"
echo "   swi-prolog-z3: $PROJECTS_ROOT/swi-prolog-z3"
echo "   z3:            $Z3_DIR"
echo ""
echo "   Esempio d'uso:"
echo "   bash \"$SCRIPT_DIR/sol2analysis.sh\" --gen-aux --stop-first-per-loop \\"
echo "     --timeout 300 --varz3 --varclpq --annotate \\"
echo "     path/to/Contratto.sol incorrect"
echo "=================================================="
