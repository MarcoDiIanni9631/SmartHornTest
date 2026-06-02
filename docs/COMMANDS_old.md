# Pipeline — Manual commands (reference only)

> **Note:** This file contains the original manual commands, kept as reference.
> For the updated pipeline using the step scripts see [`COMMANDS.md`](COMMANDS.md).

---

# Pipeline — Step-by-step commands

All commands below use these two variables — set them to your actual installation paths:

```bash
GREY_DIR=/path/to/grey
YULCHC_DIR=/path/to/yul-chc
```

---

### 1. `.sol` → `.json` — Compile Solidity to YUL (GREY)

GREY invokes `solc` on the Solidity source and produces a JSON file containing the YUL intermediate representation of the contract.

```bash
cd $GREY_DIR
python3 src/grey_main.py \
  -s /absolute/path/to/MyContract/MyContract.sol \
  -v -if sol -o output -solc ./solc-latest
mv $GREY_DIR/intermediate.json /absolute/path/to/MyContract/MyContract.json
```

> **Warning — naming matters, rename before yul2chc:**
> GREY always writes `intermediate.json` in its own root directory (not in `output/`).
> The `mv` **must rename** it to the final contract name (e.g. `MyContract.json`) before
> running yul2chc. This is because:
> - yul2chc names all its outputs after the `.json` file stem
>   (`intermediate.json` → `intermediate.pl`, `intermediate.txt`)
> - the generated `.pl` embeds `:- include('intermediate.aux.pl')` — the transform
>   will look for that exact filename regardless of any later renaming
>
> If you end up with `intermediate.*` files by mistake, either start over with the correct
> `mv`, or copy your `MyContract.aux.pl` to `intermediate.aux.pl` before running transform.
>
> Do not run multiple grey conversions in parallel — they overwrite each other.

---

### 2. `.json` → `.pl` — Translate YUL to raw CHC clauses (yul2chc)

The JSON is translated into raw Constrained Horn Clauses in Prolog syntax.
Output is written to the same directory as the `.json`.

```bash
cd $YULCHC_DIR
python3 scripts/yul2chc.py -json /absolute/path/to/MyContract/MyContract.json
```

Output: `MyContract.pl`

---

### 3. Write `aux.pl` — Define the function entry point

The `.aux.pl` file tells the interpreter which function to analyse and how to call it.
Inspect the `.pl` (look for `fun(subO_fun_*)` lines) to find the function name, its input variables, and its start block.

```prolog
% MyContract.aux.pl
evm_globals(['msg.value']).

prop(Env1, Cf0, []) :-
    Cmd = cmd(
        'START_BLOCK',                          % entry block name (from .pl)
        fun_call(subO_fun_myFunction_N,         % function name   (from .pl)
                 [num(_V_v0), num(_V_v1)], [])  % one num() per input arg
    ),
    Cf0 = cf(Cmd, Env1).
```

> `sol2tpl.py` generates this file automatically — write it by hand only if you need
> a custom entry point or want to re-use an existing `.pl`.
>
> **EVM globals injection — important constraint:**
> The `transform` tool requires `'msg.value'` to always be present in `evm_globals`.
> The reason: `initConf_env1` in the interpreter explicitly calls `lookup_list('msg.value', EG, V)`
> to force msg.value=0; if msg.value is absent from the list, that lookup fails and the
> transform produces 0 CHCs silently.
> To inject any additional EVM global, always keep `'msg.value'` in the list:
> ```prolog
> % inject msg.sender as symbolic non-zero address
> evm_globals(['msg.value', 'msg.sender']).
> prop(Env1, Cf0, [V1 > 0]) :-
>     ...
>     update(Env1, 'msg.sender', V1, Env2),
>     Cf0 = cf(Cmd, Env2).
>
> % inject block.number as symbolic non-negative integer
> evm_globals(['msg.value', 'bnumber']).
> prop(Env1, Cf0, [V1 >= 0]) :-
>     ...
>     update(Env1, 'bnumber', V1, Env2),
>     Cf0 = cf(Cmd, Env2).
> ```
> Both `msg.sender` and `block.number` injection tested and working.

---

### 4. `.pl` + `aux.pl` → `.t.pl` + `.t.pl-defs.txt` — Transform CHC clauses (transform)

The `transform` tool applies verification-condition transformations to the raw CHC clauses,
producing the final form used by the interpreter (`.t.pl`) and a predicate definitions file
(`.t.pl-defs.txt`) needed by the variable-mapping scripts.
Must be run from the yul-chc directory.

```bash
cd $YULCHC_DIR
./scripts/transform \
  --interactive \
  /absolute/path/to/MyContract/MyContract.pl \
  lib/yul/configs/vcg_multistep.iteration
```

Output: `MyContract.t.pl` and `MyContract.t.pl-defs.txt` in the same folder as the `.pl`.

---

### Steps 1–4 in one command

`sol2tpl.py` runs GREY, yul2chc, generates `aux.pl`, and runs `transform` automatically:

```bash
python3 script/sol2tpl.py test/MyContract/MyContract.sol
# or, to specify the function explicitly:
python3 script/sol2tpl.py test/MyContract/MyContract.sol myFunction
```

---

### 5. `.t.pl` → `.t_constr.pl` 

The `.t.pl` clauses use plain Prolog arithmetic. This step rewrites every arithmetic
operation using constr to contain all constraints, enabling symbolic reasoning over numeric values
during analysis.

```bash
python3 script/yulPl2Constr.py test/MyContract/MyContract.t.pl
```

Output: `MyContract.t_constr.pl` in the same folder as the `.t.pl`.

---

### 6. `.t_constr.pl` → `.zmiout` — Run the analysis

The SWI-Prolog interpreter unfolds the CHC clauses depth-first, accumulating
constraints and discharging them to Z3 at each step. When a path to an `assert`
violation is satisfiable, Z3 returns a concrete model — the counterexample. The
full call trace and Z3 model are written to a `.zmiout` file.

```bash
nohup bash script/InterpreterAnalysis5.2.sh \
  --stop-first-per-loop \
  --timeout 300 \
  test/MyContract/MyContract.t_constr.pl \
  incorrect &
```

The `.zmiout` filename encodes the outcome:
- `derivable` — a violation was found (counterexample inside)
- `nonDerivable` — no violation found within the given depth/timeout

**Analysis flags:**

| Flag | Meaning |
|---|---|
| `--stop-first-per-loop` | One counterexample per loop iteration (recommended) |
| `--stop-first` | Stop at the very first counterexample found |
| `--timeout SEC` | Timeout in seconds (default: 60000) |
| `--maxdepth N` | Maximum unfolding depth (default: 10000000) |
| `--looplimit N` | Maximum number of loop iterations |
| `--skip-existing` | Skip if a `.zmiout` already exists |
| `--debug` | Verbose output |

---

### 7. `.zmiout` → `.vars_z3.txt` / `.vars_clpq.txt` — Map to Solidity variables

The `.zmiout` contains raw Z3 variable names (e.g. `_352`, `_32314`) with no direct
connection to Solidity. This step uses the structural layout of the CHC predicates
(from `.t.pl-defs.txt`) to map each Z3 variable back to its Solidity name (state
variable or function argument), then projects the constraints onto those variables
only, eliminating internal auxiliary variables.

```bash
# Z3 backend (quantifier elimination):
python3 script/zmiout2vars_z3.py \
  test/MyContract/MyContract.sol \
  test/MyContract/MyContract.t.pl-defs.txt \
  test/MyContract/MyContract.t_constr.pl.*.zmiout

# CLP(Q) backend (projection via SWI-Prolog dump/3):
python3 script/zmiout2vars_clpq.py \
  test/MyContract/MyContract.sol \
  test/MyContract/MyContract.t.pl-defs.txt \
  test/MyContract/MyContract.t_constr.pl.*.zmiout
```

Output: `...zmiout.vars_z3.txt` and/or `...zmiout.vars_clpq.txt`

---

### 8. `.vars_z3.txt` → `.annotated.sol` — Annotate the source file

Appends the projected constraints as a `/* ... */` comment block at the end of the
original `.sol`, so witness values and conditions are readable directly alongside
the source code.

```bash
# Entire folder (auto-finds .sol + .vars_z3.txt pairs):
python3 script/annotate_sol.py test/MyContract/

# Single pair:
python3 script/annotate_sol.py \
  test/MyContract/MyContract.sol \
  "test/MyContract/MyContract.t_constr.pl.*.zmiout.vars_z3.txt"
```

Output: `MyContract.annotated.sol`
