#!/bin/bash
#
# 🔧 Setup completo ambiente VeriMap + Interprete + SWI-Prolog + Z3 + Turibe
# Tutto in user-space (NO sudo, NO modifiche permanenti)
# Autore: Marco Di Ianni
# -------------------------------------------------------------

set -e

# === Variabili principali ===
BASE_DIR="$HOME/local"
SRC_DIR="$BASE_DIR/src"
SWIPL_VERSION="9.3.31"
Z3_VERSION="4.15.3"
PROJECTS_DIR="$HOME/verimap_projects"

export SWIPL_HOME=$BASE_DIR/swipl-${SWIPL_VERSION}
export Z3_HOME=$BASE_DIR/z3-${Z3_VERSION}
export PATH=$SWIPL_HOME/bin:$Z3_HOME/bin:$PATH
export LD_LIBRARY_PATH=$Z3_HOME/lib:$LD_LIBRARY_PATH
export SWIZ3_TURIBE_PATH="${PROJECTS_DIR}/swi-prolog-z3"



# # === Repository ===
REPO_INTERPRETER="https://github.com/MarcoDiIanni9631/SmartHornTest.git"
 
# guida per installare pat github
# https://stackoverflow.com/questions/2505096/clone-a-private-repository-github
# https://github.com/settings/personal-access-tokens/new
# modificare questa veriabile pat per permettere il clone 
PAT="github_pat_xyz"
REPO_VERIMAP="https://oauth2:$PAT@github.com/chc-lab/verimap.git"

REPO_SWIPROLOG_Z3="https://github.com/MarcoDiIanni9631/swi-prolog-z3.git"
CONDAENV="zmi"



# PAT="github_pat_quellocheeee"
# REPO_VERIMAP="https://oauth2:$PAT@github.com/chc-lab/verimap.git"

# === 0. Installare conda ===
conda create -n $CONDAENV -y
conda activate $CONDAENV

# === 1. Creazione cartelle ===
echo "=== [1/8] Creazione directory locali ==="
mkdir -p "$SRC_DIR" "$PROJECTS_DIR"

# === 2. Installazione tool di compilazione ===
echo "=== [2/8] Installazione dipendenze di build (Conda) ==="
conda install -c conda-forge make cmake cxx-compiler git wget libarchive -y

# === 3. Installazione SWI-Prolog ===
echo "=== [3/8] Installazione SWI-Prolog $SWIPL_VERSION ==="
cd "$SRC_DIR"
if [ ! -f "swipl-${SWIPL_VERSION}.tar.gz" ]; then
  wget https://www.swi-prolog.org/download/devel/src/swipl-${SWIPL_VERSION}.tar.gz
fi
tar xzf swipl-${SWIPL_VERSION}.tar.gz
cd swipl-${SWIPL_VERSION}
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$BASE_DIR/swipl-${SWIPL_VERSION} ..
make -j"$(nproc)"
make install

# === 4. Installazione Z3 ===
echo "=== [4/8] Installazione Z3 $Z3_VERSION ==="
cd "$SRC_DIR"
if [ ! -f "z3-${Z3_VERSION}.tar.gz" ]; then
  wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-${Z3_VERSION}.tar.gz
fi
tar xzf z3-${Z3_VERSION}.tar.gz
cd z3-z3-${Z3_VERSION}
python scripts/mk_make.py --prefix=$BASE_DIR/z3-${Z3_VERSION}
cd build
make -j"$(nproc)"
make install

# === 5. Variabili ambiente TEMPORANEE (valide solo per questa sessione) ===
echo "=== [5/8] Impostazione temporanea variabili ambiente ==="

#per analisi manuali fare questi comandi:

# export Z3_HOME=/home/labeconomia/mdiianni2/local/z3-4.15.3
# export LD_LIBRARY_PATH=$Z3_HOME/lib:$LD_LIBRARY_PATH
# export PATH=$Z3_HOME/bin:$PATH
# export SWIPL_HOME=/home/labeconomia/mdiianni2/local/swipl-9.3.31
# export PATH=$SWIPL_HOME/bin:$PATH



# === 6. Clonazione repository ===
echo "=== [6/8] Clonazione repository ==="
cd "$PROJECTS_DIR"

if [ ! -d "smarthorntest" ]; then
  git clone "$REPO_INTERPRETER" smarthorntest
else
  (cd smarthorntest && git pull && cd ..)
fi

#usare PAT 
#PAT="github_pat_quellocheeee"
#REPO_VERIMAP="https://oauth2:$PAT@github.com/chc-lab/verimap.git" 
#
#
if [ ! -d "verimap" ]; then
  git clone "$REPO_VERIMAP"
else
  (cd verimap && git pull && cd ..)
fi

if [ ! -d "swi-prolog-z3" ]; then
  git clone "$REPO_SWIPROLOG_Z3"
else
  (cd swi-prolog-z3 && git pull && cd ..)
fi

# === 7. Compilazione libreria Turibe (swi-prolog-z3) ===
echo "=== [7/8] Compilazione libreria Prolog-Z3 (Turibe) ==="
cd "$PROJECTS_DIR/swi-prolog-z3"
swipl-ld -shared -o z3_swi_foreign.so z3_swi_foreign.c -I$Z3_HOME/include -L$Z3_HOME/lib -lz3

mkdir -p $SWIPL_HOME/lib/swipl/lib/x86_64-linux
cp z3_swi_foreign.so $SWIPL_HOME/lib/swipl/lib/x86_64-linux/

echo "✅ Libreria z3_swi_foreign.so compilata e installata"

# === 8. Verifica finale ===
echo "=== [8/8] Verifica versioni installate ==="
swipl --version
z3 --version

echo ""
echo "=============================================================="
echo "✅ SETUP COMPLETATO CON SUCCESSO"
echo "Tutti i file sono installati in: $PROJECTS_DIR"
echo ""
echo "⚠️  Attenzione: le variabili d'ambiente sono attive SOLO per questa sessione."
echo "Se vuoi attivarle manualmente in futuro, usa:"
echo ""
echo "  export SWIPL_HOME=\$HOME/local/swipl-${SWIPL_VERSION}"
echo "  export Z3_HOME=\$HOME/local/z3-${Z3_VERSION}"
echo "  export PATH=\$SWIPL_HOME/bin:\$Z3_HOME/bin:\$PATH"
echo "  export LD_LIBRARY_PATH=\$Z3_HOME/lib:\$LD_LIBRARY_PATH"
echo ""
echo "=============================================================="
