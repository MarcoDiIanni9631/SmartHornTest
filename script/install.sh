#!/bin/bash
# install.sh: sets up what the SmartHornTest pipeline needs
# (grey, yul-chc, swi-prolog-z3, Z3, forge-std) as sibling folders of this
# repo, and compiles the SWI-Prolog/Z3 bridge. At the end it checks the
# tools it does not install (solc, VeriMAP, Foundry, z3-solver, chcviz) and
# says which parts of the pipeline need them.
#
# Usage:
#   bash script/install.sh
#
# This script does NOT install system packages (no sudo/apt). If a
# required tool is missing, it stops and tells you what to install
# manually. This is on purpose: some servers don't give root access.
#
# Environment variable overrides:
#   GREY_REPO_URL, YULCHC_REPO_URL, SWIZ3_REPO_URL   (default: MarcoDiIanni9631's forks)
#   ARCHIVE_URL                                       (default: Z3 4.15.2, linux x64, glibc 2.39;
#                                                      with an older glibc the Z3 of the z3-solver
#                                                      Python package is used instead)
#   SKIP_Z3=1                                          (skip the Z3 download, use Z3_LIB_DIR/Z3_INCLUDE already set)
#   SWIPL_BIN                                          (path to swipl, if it is not on your PATH)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PROJECTS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREY_REPO_URL="${GREY_REPO_URL:-https://github.com/MarcoDiIanni9631/grey.git}"
YULCHC_REPO_URL="${YULCHC_REPO_URL:-https://github.com/MarcoDiIanni9631/yul-chc.git}"
SWIZ3_REPO_URL="${SWIZ3_REPO_URL:-https://github.com/MarcoDiIanni9631/swi-prolog-z3.git}"
ARCHIVE_URL="${ARCHIVE_URL:-https://github.com/Z3Prover/z3/releases/download/z3-4.15.2/z3-4.15.2-x64-glibc-2.39.zip}"
SKIP_Z3="${SKIP_Z3:-0}"

echo "=================================================="
echo "Installing SmartHornTest in: $PROJECTS_ROOT"
echo "=================================================="

# ------------------------------------------------------------------
# 1. Find swipl / swipl-ld (respects SWIPL_BIN if it is already set,
#    e.g. when swipl was built from source in a custom folder)
# ------------------------------------------------------------------
SWIPL_BIN="${SWIPL_BIN:-$(command -v swipl || true)}"
if [ -n "$SWIPL_BIN" ] && [ -x "$SWIPL_BIN" ]; then
  SWIPL_LD_BIN="$(dirname "$SWIPL_BIN")/swipl-ld"
  [ -x "$SWIPL_LD_BIN" ] || SWIPL_LD_BIN="$(command -v swipl-ld || true)"
else
  SWIPL_BIN=""
  SWIPL_LD_BIN="$(command -v swipl-ld || true)"
fi

# ------------------------------------------------------------------
# 2. Check the other required tools (no auto-install)
# ------------------------------------------------------------------
missing=()
[ -n "$SWIPL_BIN" ] && [ -x "$SWIPL_BIN" ] || missing+=("swipl")
[ -n "$SWIPL_LD_BIN" ] && [ -x "$SWIPL_LD_BIN" ] || missing+=("swipl-ld")
for cmd in git python3 gcc unzip rsync; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  missing+=("curl or wget")
fi
if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing tools: ${missing[*]}"
  echo "Install them (e.g. 'sudo apt install swi-prolog build-essential unzip curl') and run this script again."
  echo "If swipl is already installed but not on your PATH, set SWIPL_BIN=/path/to/swipl and try again."
  exit 1
fi
echo "OK: all required tools found (swipl, swipl-ld, git, python3, gcc, unzip, rsync)"

download() {
  # download <url> <destination file>
  if command -v curl >/dev/null 2>&1; then
    curl -sL -o "$2" "$1"
  else
    wget -q -O "$2" "$1"
  fi
}

# ------------------------------------------------------------------
# 3. Clone grey, yul-chc, swi-prolog-z3 as sibling folders
#    (skipped if the folder is already there)
# ------------------------------------------------------------------
clone_if_missing() {
  local dir="$1" url="$2"
  if [ -d "$dir/.git" ]; then
    echo "Skipping $(basename "$dir"): already cloned"
  else
    echo "Cloning $(basename "$dir")..."
    git clone --quiet "$url" "$dir"
  fi
}

clone_if_missing "$PROJECTS_ROOT/grey" "$GREY_REPO_URL"
clone_if_missing "$PROJECTS_ROOT/yul-chc" "$YULCHC_REPO_URL"
clone_if_missing "$PROJECTS_ROOT/swi-prolog-z3" "$SWIZ3_REPO_URL"
# forge-std: used by witnesses2foundry.py to write the Foundry tests
if [ -f "$PROJECTS_ROOT/forge-std/src/Test.sol" ]; then
  echo "Skipping forge-std: already cloned"
else
  echo "Cloning forge-std..."
  git clone --quiet --depth 1 --branch "${FORGE_STD_TAG:-v1.9.7}" https://github.com/foundry-rs/forge-std.git "$PROJECTS_ROOT/forge-std"
fi
chmod +x "$PROJECTS_ROOT/grey/solc-latest"

# ------------------------------------------------------------------
# 4. Z3: download the prebuilt binary release (skipped if already
#    present, or if SKIP_Z3=1 and you already set Z3_LIB_DIR/Z3_INCLUDE)
# ------------------------------------------------------------------
Z3_DIR="$PROJECTS_ROOT/z3"
if [ "$SKIP_Z3" = "1" ]; then
  echo "SKIP_Z3=1: skipping the Z3 download, using Z3_LIB_DIR/Z3_INCLUDE already set"
elif [ -f "$Z3_DIR/bin/libz3.so" ] && [ -f "$Z3_DIR/include/z3_api.h" ]; then
  echo "Skipping Z3: already downloaded in $Z3_DIR"
elif [ "$(printf '%s\n' "$(ldd --version | head -1 | grep -o '[0-9]*\.[0-9]*$')" 2.39 | sort -V | head -1)" != 2.39 ] \
     && PYZ3="$(python3 -c 'import z3, os; print(os.path.dirname(z3.__file__))' 2>/dev/null)" \
     && [ -f "$PYZ3/lib/libz3.so" ] && [ -f "$PYZ3/include/z3_api.h" ]; then
  # the prebuilt release needs glibc 2.39: on an older system use the libz3
  # of the z3-solver Python package, which is built for older glibc versions
  echo "glibc older than 2.39: using the Z3 of the z3-solver Python package ($PYZ3)"
  mkdir -p "$Z3_DIR"
  ln -sfn "$PYZ3/lib" "$Z3_DIR/bin"
  ln -sfn "$PYZ3/include" "$Z3_DIR/include"
else
  echo "Downloading Z3 from $ARCHIVE_URL"
  echo "(If your machine is not linux x86_64/glibc, set ARCHIVE_URL to the right"
  echo " release from https://github.com/Z3Prover/z3/releases and run again.)"
  TMPZIP="$(mktemp --suffix=.zip)"
  download "$ARCHIVE_URL" "$TMPZIP"
  TMPEXTRACT="$(mktemp -d)"
  unzip -q "$TMPZIP" -d "$TMPEXTRACT"
  rm -f "$TMPZIP"
  mkdir -p "$Z3_DIR"
  # flatten the versioned folder (z3-X.Y.Z-.../{bin,include}) into $Z3_DIR
  SRC="$(find "$TMPEXTRACT" -maxdepth 1 -mindepth 1 -type d | head -1)"
  rsync -a "$SRC"/ "$Z3_DIR"/
  rm -rf "$TMPEXTRACT"
fi

# ------------------------------------------------------------------
# 5. Compile the SWI-Prolog / Z3 bridge
# ------------------------------------------------------------------
echo "Compiling z3_swi_foreign.so..."
Z3_INCLUDE="${Z3_INCLUDE:-$Z3_DIR/include}"
Z3_LIBDIR="${Z3_LIB_DIR:-$Z3_DIR/bin}"
(
  cd "$PROJECTS_ROOT/swi-prolog-z3"
  "$SWIPL_LD_BIN" -shared -o z3_swi_foreign.so z3_swi_foreign.c -I"$Z3_INCLUDE" -L"$Z3_LIBDIR" -lz3
)
echo "Bridge compiled"

# ------------------------------------------------------------------
# 6. Self-test: does SWI-Prolog load the bridge correctly?
# ------------------------------------------------------------------
echo "Testing that the bridge loads..."
BRIDGE_SO="$PROJECTS_ROOT/swi-prolog-z3/z3_swi_foreign.so"
LD_LIBRARY_PATH="$Z3_LIBDIR:$PROJECTS_ROOT/swi-prolog-z3:${LD_LIBRARY_PATH:-}" \
  "$SWIPL_BIN" -q -g "load_foreign_library('$BRIDGE_SO'), writeln('BRIDGE OK'), halt" \
  -t "halt(1)" 2>&1

# ------------------------------------------------------------------
# 7. Tools this script does not install: only some parts need them
# ------------------------------------------------------------------
echo ""
echo "Other tools (not installed by this script):"
check() {  # check <ok?> <name> <what needs it>
  if [ "$1" = 1 ]; then echo "   OK       $2"; else echo "   MISSING  $2: needed for $3"; fi
}
check "$(command -v solc >/dev/null && echo 1)" "solc" "the SolCMC route (https://github.com/ethereum/solidity/releases)"
VM="${VERIMAP:-$PROJECTS_ROOT/verimap}"
check "$([ -x "$VM/scripts/smt2map" ] && echo 1)" "VeriMAP ($VM/scripts/smt2map)" "the SolCMC route (set VERIMAP=/path/to/verimap)"
check "$(command -v forge >/dev/null && echo 1)" "forge" "the Foundry tests and coverage (https://getfoundry.sh)"
check "$(python3 -c 'import z3' 2>/dev/null && echo 1)" "z3-solver (Python)" "the projected constraints (pip install z3-solver)"
check "$(command -v chcviz >/dev/null && echo 1)" "chcviz" "the CHC graph, --graph/--highlight (https://github.com/MarcoDiIanni9631/CHCViz)"

echo ""
echo "=================================================="
echo "Setup complete."
echo "   grey:          $PROJECTS_ROOT/grey"
echo "   yul-chc:       $PROJECTS_ROOT/yul-chc"
echo "   swi-prolog-z3: $PROJECTS_ROOT/swi-prolog-z3"
echo "   z3:            $Z3_DIR"
echo "   forge-std:     $PROJECTS_ROOT/forge-std"
echo ""
echo "   Try it:"
echo "   bash \"$(dirname "$SCRIPT_DIR")/smarthorntest_completo.sh\" path/to/Contract.sol -f functionName"
echo "=================================================="
