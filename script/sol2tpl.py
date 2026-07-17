#!/usr/bin/env python3
"""
sol2tpl.py — Pipeline completo: Solidity → .pl → aux.pl → .t.pl

Uso:
    python3 sol2tpl.py /percorso/Contratto.sol [nome_funzione]

    nome_funzione: opzionale (es. 'claimRewards').
                   Se non fornito e ci sono più funzioni, viene chiesto
                   interattivamente quale scegliere.
"""

import os
import sys
import re
import subprocess
import shutil

# ==============================
# PERCORSI — configurabili via variabili d'ambiente
# ==============================
# Locali (default):
#   SOL2TPL_GREY     = /home/marco/Downloads/grey
#   SOL2TPL_YULCHC   = /home/marco/Desktop/yul9Marzo/yul-chc
# Server (impostare prima di lanciare):
#   SOL2TPL_GREY     = /home/labeconomia/mdiianni/verimap_projects/grey
#   SOL2TPL_YULCHC   = /home/labeconomia/mdiianni/verimap_projects/yul-chc

_VERIMAP        = "/home/labeconomia/mdiianni/verimap_projects"
PATH_GREY       = os.environ.get("SOL2TPL_GREY",   os.path.join(_VERIMAP, "grey"))
PATH_YUL_CHC    = os.environ.get("SOL2TPL_YULCHC", os.path.join(_VERIMAP, "yul-chc"))
SOLC_PATH       = os.environ.get("SOL2TPL_SOLC",   os.path.join(PATH_GREY, "solc-latest"))
TRANSFORM_BIN   = os.path.join(PATH_YUL_CHC, "scripts/transform")
TRANSFORM_CFG   = "lib/yul/configs/vcg_multistep.iteration"

# ==============================
# UTILS
# ==============================

def run_command(cmd, cwd=None):
    print(f"\n[RUNNING] {' '.join(str(c) for c in cmd)}\n")
    result = subprocess.run(cmd, cwd=cwd)
    if result.returncode != 0:
        print("\n[ERRORE] Comando fallito. Interrompo il pipeline.")
        sys.exit(1)

def banner(msg):
    sep = "=" * 50
    print(f"\n{sep}\n{msg}\n{sep}\n")

# ==============================
# STEP 1+2: Solidity → .pl
# ==============================

def run_sol2pl(sol_path):
    sol_dir   = os.path.dirname(sol_path)
    base_name = os.path.splitext(os.path.basename(sol_path))[0]
    json_path = os.path.join(sol_dir, base_name + ".json")
    pl_path   = os.path.join(sol_dir, base_name + ".pl")

    # GREY: Solidity → intermediate.json
    intermediate = os.path.join(PATH_GREY, "intermediate.json")
    if os.path.isfile(intermediate):
        os.remove(intermediate)

    run_command([
        "python3", "src/grey_main.py",
        "-s", sol_path, "-v", "-if", "sol",
        "-o", "output", "-solc", SOLC_PATH
    ], cwd=PATH_GREY)
    if not os.path.isfile(intermediate):
        print("[ERRORE] intermediate.json non generato da GREY.")
        sys.exit(1)
    shutil.move(intermediate, json_path)
    print(f"[OK] JSON → {json_path}")

    # yul2chc: JSON → .pl
    run_command([
        "python3", "scripts/yul2chc.py", "-json", json_path
    ], cwd=PATH_YUL_CHC)

    if not os.path.isfile(pl_path):
        print("[ERRORE] .pl non generato da yul2chc.")
        sys.exit(1)
    print(f"[OK] .pl  → {pl_path}")

    return pl_path

# ==============================
# STEP 3: Parsing funzioni dal .pl
# ==============================

def parse_fun_declarations(pl_path):
    """
    Estrae le dichiarazioni subO_fun_* dal file .pl.
    Ritorna lista di dict con: name, inputs (lista var), start_block.
    """
    pattern = re.compile(
        r"^fun\(\s*(subO_fun_\w+)\s*,\s*(\[.*?\])\s*,\s*(\[.*?\])\s*,\s*'(\w+)'\s*\)\."
    )
    funs = []
    with open(pl_path) as f:
        for line in f:
            m = pattern.match(line.strip())
            if m:
                name, inputs_raw, _outputs_raw, start_block = m.groups()
                inputs = re.findall(r'var\((\w+)\)', inputs_raw)
                funs.append({
                    'name':        name,
                    'inputs':      inputs,
                    'start_block': start_block,
                })
    return funs

def choose_function(funs, hint=None):
    """Seleziona la funzione da usare nell'aux.pl."""
    if not funs:
        print("[ERRORE] Nessuna funzione subO_fun_* trovata nel .pl.")
        sys.exit(1)

    # Prova a filtrare con l'hint
    if hint:
        candidates = [f for f in funs if hint.lower() in f['name'].lower()]
        if len(candidates) == 1:
            return candidates[0]
        if len(candidates) > 1:
            funs = candidates   # restringe la scelta

    if len(funs) == 1:
        print(f"[OK] Function selected automatically: {funs[0]['name']}")
        return funs[0]

    # Selezione interattiva
    print("\nFunzioni disponibili:")
    for i, f in enumerate(funs):
        inp = f['inputs'] if f['inputs'] else 'nessuno'
        print(f"  [{i}] {f['name']}")
        print(f"       input: {inp}")
        print(f"       start: {f['start_block']}")
    choice = input("\nScegli l'indice della funzione: ").strip()
    return funs[int(choice)]

# ==============================
# STEP 4: Genera aux.pl
# ==============================

def generate_aux_pl(aux_path, fun, sol_path):
    """Scrive il file aux.pl per la funzione scelta."""
    func_name   = fun['name']
    start_block = fun['start_block']
    inputs      = fun['inputs']

    if inputs:
        input_list = "[" + ", ".join(f"num(_V_{v})" for v in inputs) + "]"
    else:
        input_list = "[]"

    content = f"""\
evm_globals(['msg.value']).

prop(Env1, Cf0, []) :-
    Cmd = cmd(
        '{start_block}',
        fun_call({func_name}, {input_list}, [])
    ),
    Cf0 = cf(Cmd, Env1).
"""
    with open(aux_path, 'w') as f:
        f.write(content)
    print(f"[OK] aux.pl → {aux_path}")

# ==============================
# STEP 5: transform → .t.pl
# ==============================

def run_transform(pl_path):
    run_command(
        [TRANSFORM_BIN, "--interactive", pl_path, TRANSFORM_CFG],
        cwd=PATH_YUL_CHC
    )
    t_pl_path = os.path.splitext(pl_path)[0] + ".t.pl"
    if not os.path.isfile(t_pl_path):
        print("[ERRORE] .t.pl non generato da transform.")
        sys.exit(1)
    print(f"[OK] .t.pl → {t_pl_path}")
    return t_pl_path

# ==============================
# MAIN
# ==============================

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 sol2tpl.py /percorso/Contratto.sol [nome_funzione]")
        sys.exit(1)

    sol_path  = os.path.abspath(sys.argv[1])
    func_hint = sys.argv[2] if len(sys.argv) > 2 else None

    if not os.path.isfile(sol_path):
        print(f"[ERRORE] File non trovato: {sol_path}")
        sys.exit(1)

    sol_dir   = os.path.dirname(sol_path)
    base_name = os.path.splitext(os.path.basename(sol_path))[0]
    aux_path  = os.path.join(sol_dir, base_name + ".aux.pl")

    banner("sol2tpl.py — Solidity → .t.pl")

    # 1+2: Solidity → .pl
    print("STEP 1+2 — Solidity → .pl  (GREY + yul2chc)")
    pl_path = run_sol2pl(sol_path)

    # 3: Leggi funzioni
    print("\nSTEP 3 — Parsing funzioni dal .pl ...")
    funs = parse_fun_declarations(pl_path)
    fun  = choose_function(funs, func_hint)
    print(f"          Funzione: {fun['name']}")
    print(f"          Input   : {fun['inputs'] if fun['inputs'] else 'nessuno'}")
    print(f"          Start   : {fun['start_block']}")

    # 4: Genera aux.pl
    print("\nSTEP 4 — Generazione aux.pl ...")
    generate_aux_pl(aux_path, fun, sol_path)

    # 5: transform
    print("\nSTEP 5 — transform → .t.pl ...")
    t_pl_path = run_transform(pl_path)

    banner("Pipeline completato!")
    print(f"  .pl    → {pl_path}")
    print(f"  aux.pl → {aux_path}")
    print(f"  .t.pl  → {t_pl_path}")
    print()

if __name__ == "__main__":
    main()
