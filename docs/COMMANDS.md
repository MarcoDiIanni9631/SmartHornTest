# Pipeline — Step-by-step scripts

Each script handles a single pipeline step.
Output files are written to the same folder as the input file, with the correct name automatically.

> For the original manual commands (reference only): see [`COMMANDS_old.md`](COMMANDS_old.md)

---

### Step 1 — `.sol` → `.json` (GREY)

```bash
bash script/step1_grey.sh test/MyContract/MyContract.sol
```

Output: `test/MyContract/MyContract.json`

---

### Step 2 — `.json` → `.pl` (yul2chc)

```bash
bash script/step2_yul2chc.sh test/MyContract/MyContract.json
```

Output: `test/MyContract/MyContract.pl`

---

### Step 3 — Write `aux.pl`

Before running the transform, create `MyContract.aux.pl` in the same folder as the `.pl`.
Find the function name and entry block with:

```bash
grep "^fun(subO_fun_" test/MyContract/MyContract.pl
```

```prolog
% MyContract.aux.pl
evm_globals(['msg.value']).          % msg.value is always mandatory

prop(Env1, Cf0, []) :-
    Cmd = cmd(
        'START_BLOCK',               % entry block name (from .pl grep above)
        fun_call(subO_fun_myFunction_N, [], [])
    ),
    Cf0 = cf(Cmd, Env1).
```

> **EVM globals injection:** to inject additional EVM variables (e.g. block.timestamp),
> add them to `evm_globals` and use `update/4` in `prop`. `msg.value` must always be present.
> ```prolog
> evm_globals(['msg.value', 'timestamp']).
> prop(Env1, Cf0, [V1 >= 1]) :-
>     ...
>     update(Env1, 'timestamp', V1, Env2),
>     Cf0 = cf(Cmd, Env2).
> ```
> Available variables: `'msg.sender'`, `'bnumber'`, `'timestamp'`, `'tsender'`, `'gprice'`, `'glimit'`, `'basefee'`, `'chainid'`, `'balance'`

---

### Step 4 — `.pl` + `aux.pl` → `.t.pl` (transform)

```bash
bash script/step3_transform.sh test/MyContract/MyContract.pl
```

Output: `test/MyContract/MyContract.t.pl` and `MyContract.t.pl-defs.txt`

> Requires `MyContract.aux.pl` to exist in the same folder.

---

### Step 5 — `.t.pl` → `.t_constr.pl`

```bash
bash script/step4_constr.sh test/MyContract/MyContract.t.pl
```

Output: `test/MyContract/MyContract.t_constr.pl`

---

### Step 6 — `.t_constr.pl` → `.zmiout` (analysis)

```bash
bash script/step5_analysis.sh --stop-first-per-loop --timeout 300 test/MyContract/MyContract.t_constr.pl incorrect
```

Output: `test/MyContract/MyContract.t_constr.pl.*.zmiout`

The `.zmiout` filename encodes the outcome:
- `derivable` — a violation was found (counterexample inside)
- `nonDerivable` — no violation found within the given depth/timeout

**Available flags:**

| Flag | Meaning |
|---|---|
| `--stop-first-per-loop` | One counterexample per loop iteration (recommended) |
| `--stop-first` | Stop at the very first counterexample found |
| `--timeout SEC` | Timeout in seconds (default: 300) |
| `--maxdepth N` | Maximum unfolding depth |
| `--looplimit N` | Maximum number of loop iterations |
| `--skip-existing` | Skip if a `.zmiout` already exists |
| `--debug` | Verbose output |

---

### Step 7 — `.zmiout` → `.vars_z3.txt` / `.vars_clpq.txt` (variable mapping)

```bash
bash script/step6_vars.sh --z3 test/MyContract/MyContract.sol \
  test/MyContract/MyContract.t.pl-defs.txt \
  test/MyContract/MyContract.t_constr.pl.*.zmiout
```

Options: `--z3` (default), `--clpq`, both combinable.

Output: `...zmiout.vars_z3.txt` and/or `...zmiout.vars_clpq.txt`

---

### Step 8 — `.t.pl` → CHC graph SVG (chcviz)

```bash
bash script/step7_graph.sh test/MyContract/MyContract.t.pl
```

Output: `test/MyContract/dot_dias/MyContract.t_clean_object_xref_diagram.dot.svg`

---

### Step 9 — `.sol` → `.annotated.sol`

```bash
bash script/step8_annotate.sh test/MyContract/MyContract.sol
```

Requires a `.vars_z3.txt` file in the same folder. Output: `MyContract.annotated.sol`

---

### Full pipeline in one command

To run all steps at once (`.sol` through analysis):

```bash
nohup bash script/sol2analysis.sh \
  --stop-first-per-loop --timeout 300 \
  test/MyContract/MyContract.sol \
  incorrect &
```
