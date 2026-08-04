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

### Step 10 — highlight the derivation path on the CHC graph

```bash
bash script/step9_highlight.sh --all-tests test/MyContract/MyContract.t.pl
```

This is what `sol2analysis.sh --highlight` (the full pipeline) runs. It
requires the `.dot` graph from Step 8 and a `.zmiout` from Step 6 in the
same folder, and produces **one highlighted graph (+ interactive HTML) per
test found in the `.zmiout`** — one per violation (`testFail`/
`testUnknown`) plus one per `testVerimapGood` test — instead of a single
combined one, so nothing is picked/skipped. Each test's `📌 CALL TRACE` is
re-colored over the existing graph (bold red for a violation, bold green
for a `testVerimapGood` test, everything else grayed out), plus a
`MyContract_alltests_index.html` linking every generated page.

Output: `dot_dias/MyContract_alltests_index.html` and, per test,
`dot_dias/MyContract.t_clean_object_xref_diagram_testN_<kind>_highlighted.{dot,dot.svg,html}`.

Called without `--all-tests`, `step9_highlight.sh` instead auto-picks a
single pair to compare (first violation + first `testVerimapGood`, drawn
together — shared trunk in blue, the parts where they diverge in red/green,
the split point outlined in orange) or, if only one kind is present, just
that single path in bold. Useful for a quick one-off comparison. To compare
two specific tests (e.g. two different `.zmiout` files, or two specific
test indices in the same file) call the underlying script directly:

```bash
python3 script/zmiout2dot_highlight.py <graph.dot> <zmiout1> [zmiout2] \
  [--test1 N] [--test2 N] [--single] [-o out.dot]
```

---

### Steps 1–4 in one command (conversion only)

```bash
bash script/sol2constr.sh test/MyContract/MyContract.sol
```

Runs step1 → step2 → step3 → step4 in sequence.
Requires `MyContract.aux.pl` to exist in the same folder (needed by step 3).

---

### Full pipeline in one command

`sol2analysis.sh` orchestrates all steps by calling the individual step scripts.

```bash
nohup bash script/sol2analysis.sh \
  --stop-first-per-loop --timeout 300 \
  --varz3 --varclpq --annotate \
  test/MyContract/MyContract.sol \
  incorrect &
```

**Pipeline flags:**

| Flag | Effect |
|---|---|
| `--until-tpl` | Run steps 1-4 only (equivalent to `sol2constr.sh`) |
| `--skip-convert` | Skip steps 1-4 (use existing `.t_constr.pl`) |
| `--varz3` | Run step 6 with Z3 backend after analysis |
| `--varclpq` | Run step 6 with CLPQ backend after analysis |
| `--graph` | Run step 7 (CHC graph) after conversion |
| `--annotate` | Run step 8 (annotated `.sol`) after analysis |

All `--stop-first`, `--timeout`, `--maxdepth`, etc. flags are forwarded to step 5.
