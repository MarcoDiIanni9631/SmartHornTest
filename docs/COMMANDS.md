# Pipeline: step-by-step scripts

Each script handles a single step of the yul2chc route.
Output files are written to the same folder as the input file, with the correct name automatically.

For the whole process in one command (both routes, Foundry tests, coverage) use
`smarthorntest_completo.sh`, described in the [README](../README.md). The SolCMC
route and the Foundry steps are at the end of this page.

## Overview

| Step | Script | What it does |
|---|---|---|
| 1 | `step1_grey.sh` | Compile Solidity to Yul IR (GREY) |
| 2 | `step2_yul2chc.sh` | Translate the Yul IR into raw CHC clauses |
| 3 | *(manual)* `MyContract.aux.pl` | Declare the function entry point to analyze |
| 4 | `step3_transform.sh` | Clean up the CHC clauses into `.t.pl` + `.t.pl-defs.txt` |
| 5 | `step4_constr.sh` | Add CLP(Q) constraints to the CHC clauses |
| 6 | `step5_analysis.sh` | Run the CLP(Q)+Z3 interpreter; try to derive a violation |
| 7 | `step6_vars.sh` | Project the counterexample onto concrete Solidity variable values |
| 8 | `step7_graph.sh` | Render the CHC dependency graph (via chcviz) |
| 9 | `step8_annotate.sh` | Annotate the original `.sol` with the projected constraints |
| 10 | `step9_highlight.sh` | Highlight each test's derivation path on the CHC graph, as clickable HTML with a counterexample-values panel |
| 11 | `step10_sol_cfg.sh` | Generate each function's Solidity-level CFG (via Slither), cross-linked with the CHC graph from step 10 |

---

### Step 1: `.sol` → `.json` (GREY)

```bash
bash script/step1_grey.sh path/to/MyContract/MyContract.sol
```

Output: `path/to/MyContract/MyContract.json`

---

### Step 2: `.json` → `.pl` (yul2chc)

```bash
bash script/step2_yul2chc.sh path/to/MyContract/MyContract.json
```

Output: `path/to/MyContract/MyContract.pl`

---

### Step 3: Write `aux.pl`

Before running the transform, create `MyContract.aux.pl` in the same folder as the `.pl`.
Find the function name and entry block with:

```bash
grep "^fun(subO_fun_" path/to/MyContract/MyContract.pl
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

### Step 4: `.pl` + `aux.pl` → `.t.pl` (transform)

```bash
bash script/step3_transform.sh path/to/MyContract/MyContract.pl
```

Output: `path/to/MyContract/MyContract.t.pl` and `MyContract.t.pl-defs.txt`

> Requires `MyContract.aux.pl` to exist in the same folder.

---

### Step 5: `.t.pl` → `.t_constr.pl`

```bash
bash script/step4_constr.sh path/to/MyContract/MyContract.t.pl
```

Output: `path/to/MyContract/MyContract.t_constr.pl`

---

### Step 6: `.t_constr.pl` → `.zmiout` (analysis)

```bash
bash script/step5_analysis.sh --maxdepth 100 --timeout 600 path/to/MyContract/MyContract.t_constr.pl incorrect
```

Output: `path/to/MyContract/MyContract.t_constr.pl.*.zmiout`

The `.zmiout` filename encodes the outcome:
- `derivable`: a violation was found (counterexample inside)
- `nonDerivable`: no violation found within the given depth/timeout

**Available flags:**

| Flag | Meaning |
|---|---|
| `--timeout SEC` | Timeout in seconds (default: 300) |
| `--maxdepth N` | Maximum number of resolution steps |
| `--skip-existing` | Skip if a `.zmiout` already exists |
| `--debug` | Verbose output |

---

### Step 7: `.zmiout` → `.vars_z3.txt` / `.vars_clpq.txt` (variable mapping)

```bash
bash script/step6_vars.sh --z3 path/to/MyContract/MyContract.sol \
  path/to/MyContract/MyContract.t.pl-defs.txt \
  path/to/MyContract/MyContract.t_constr.pl.*.zmiout
```

Options: `--z3` (default), `--clpq`, both combinable.

Output: `...zmiout.vars_z3.txt` and/or `...zmiout.vars_clpq.txt`

---

### Step 8: `.t.pl` → CHC graph SVG (chcviz)

```bash
bash script/step7_graph.sh path/to/MyContract/MyContract.t.pl
```

Output: `path/to/MyContract/dot_dias/MyContract.t_clean_object_xref_diagram.dot.svg`

---

### Step 9: `.sol` → `.annotated.sol`

```bash
bash script/step8_annotate.sh path/to/MyContract/MyContract.sol
```

Requires a `.vars_z3.txt` file in the same folder. Output: `MyContract.annotated.sol`

---

### Step 10: highlight the derivation path on the CHC graph

```bash
bash script/step9_highlight.sh --all-tests path/to/MyContract/MyContract.t.pl
```

This is what `sol2analysis.sh --highlight` (the full pipeline) runs. It
requires the `.dot` graph from Step 8 and a `.zmiout` from Step 6 in the
same folder, and produces **one highlighted graph (+ interactive HTML) per
test found in the `.zmiout`** (one per violation (`testFail`/
`testUnknown`) plus one per `testVerimapGood` test) instead of a single
combined one, so nothing is picked/skipped. Each test's `📌 CALL TRACE` is
re-colored over the existing graph (bold red for a violation, bold green
for a `testVerimapGood` test, everything else grayed out), plus a
`MyContract_alltests_index.html` linking every generated page.

Output: `dot_dias/MyContract_alltests_index.html` and, per test,
`dot_dias/MyContract.t_clean_object_xref_diagram_testN_<kind>_highlighted.{dot,dot.svg,html}`.

Called without `--all-tests`, `step9_highlight.sh` instead auto-picks a
single pair to compare (first violation + first `testVerimapGood`, drawn
together: shared trunk in blue, the parts where they diverge in red/green,
the split point outlined in orange) or, if only one kind is present, just
that single path in bold. Useful for a quick one-off comparison. To compare
two specific tests (e.g. two different `.zmiout` files, or two specific
test indices in the same file) call the underlying script directly:

```bash
python3 script/zmiout2dot_highlight.py <graph.dot> <zmiout1> [zmiout2] \
  [--test1 N] [--test2 N] [--single] [-o out.dot]
```

---

### Step 11: `.sol` → Solidity CFG per function (Slither), linked to the CHC graph

```bash
bash script/step10_sol_cfg.sh path/to/MyContract/MyContract.sol
```

Runs Slither's `--print cfg` on the contract and wraps the resulting `.dot`
(one per function) into the same pannable/zoomable HTML viewer used for the
CHC graph. Unlike the CHC graph (predicates over Yul blocks), this is the
control-flow graph at the Solidity source level: useful on its own, and as
a point of comparison against a "black-box" static analyzer.

If step 10's `dot_dias/MyContract_alltests_index.html` already exists, this
step cross-links the two: every CHC node that resolves to a known function
(via the same best-effort `.sol` name matching `dot2html.py` already does)
gets a "View in the Slither CFG" link in its panel, and every Slither CFG
page gets a link back to the CHC graph. Run step 10 first if you want the
link; order does not matter otherwise, and everything degrades gracefully
if one side is missing.

Output: `dot_dias/sol_cfg/index.html` and, per function,
`dot_dias/sol_cfg/MyContract.sol-Contract-function(args).html`.

> Not yet wired into `sol2analysis.sh`: run it as a separate step after
> `--graph`/`--highlight`. Requires Slither (see `script/config.sh` for the
> `SLITHER_DIR`/`SLITHER_PY`/`SLITHER_BIN` setup).

---

### Steps 1-4 in one command (conversion only)

```bash
bash script/sol2constr.sh path/to/MyContract/MyContract.sol
```

Runs step1 → step2 → step3 → step4 in sequence.
Requires `MyContract.aux.pl` to exist in the same folder (needed by step 3).

---

### Full pipeline in one command

`sol2analysis.sh` orchestrates all steps by calling the individual step scripts.

```bash
nohup bash script/sol2analysis.sh \
  --gen-aux --maxdepth 100 --timeout 600 \
  --varz3 --varclpq --annotate \
  path/to/MyContract/MyContract.sol \
  incorrect &
```

**Pipeline flags:**

| Flag | Effect |
|---|---|
| `--until-tpl` | Run steps 1-4 only (equivalent to `sol2constr.sh`) |
| `--gen-aux` | Write `MyContract.aux.pl` automatically (add `--aux-hint _name_` to pick the function) |
| `--skip-convert` | Skip steps 1-4 (use existing `.t_constr.pl`) |
| `--varz3` | Run step 6 with Z3 backend after analysis |
| `--varclpq` | Run step 6 with CLPQ backend after analysis |
| `--graph` | Run step 7 (CHC graph) after conversion |
| `--annotate` | Run step 8 (annotated `.sol`) after analysis |

`--timeout`, `--maxdepth`, `--skip-existing` and `--debug` are forwarded to step 5.

---

## Positive tests: the `vgood` marker

```bash
python3 script/add_vgood.py MyContract.sol MyContract_vgood.sol
```

Adds `uint256 vgood = 42;` at the start of every function and
`vgood = 1042; assert(vgood < 20);` before every `return` and at the end.
That assert fails exactly on the paths that pass every real assert, so the
analysis also finds those paths: they become **positive** tests (the model
holds the value 1042). Paths that break a real assert are **negative** tests.
Analyse the `_vgood.sol` file; run the Foundry tests on the original one.

---

## SolCMC route (CHCs written by solc)

The second route takes the CHCs from the solc model checker instead of Yul.
It analyses every public function, one transaction after the constructor.
In the folder `path/to/MyContract/` (holding `MyContract.sol`):

```bash
# 1. solc writes the CHC query (SMT-LIB); keep the last query in MyContract_solc.smt2
solc MyContract.sol --model-checker-engine chc --model-checker-solvers smtlib2 --model-checker-print-query --model-checker-targets assert > solc_query.txt 2>&1
awk '/Info: CHC: Requested query:/{buf=""; on=1; next} on{buf=buf $0 "\n"} /^\(check-sat\)/{if(on){last=buf; on=0}} END{printf "%s", last}' solc_query.txt > MyContract_solc.smt2

# 2. the asserts become goals to reach
python3 script/solcmc_assume_asserts.py MyContract_solc.smt2 MyContract.smt2

# 3. SMT-LIB -> Prolog (VeriMAP)
cd $VERIMAP && ./scripts/smt2map path/to/MyContract/MyContract.smt2

# 4. Prolog -> CHCs for the interpreter
swipl -q -g main -t halt script/smt2pl_to_constr.pl -- --single-tx MyContract.smt2.pl MyContract.chc.pl

# 5. interpreter (target ff)
cd script && bash InterpreterAnalysis5.2.sh --maxdepth 100 --timeout 600 path/to/MyContract/MyContract.chc.pl ff

# 6. values and constraints with Solidity names
python3 script/solcmc_zmiout2json.py path/to/MyContract
```

`smarthorntest_completo.sh -s solcmc` runs these steps (with the exact
commands written to `comandi.txt`).

---

## Foundry tests and coverage

```bash
python3 script/witnesses2foundry.py --forge-std out_dir path/to/results
cp MyContract.sol out_dir/src/<group>__MyContract.sol   # the original, without vgood
cd out_dir && forge test --offline --match-path 'test/*' --json > forge.json
```

`witnesses2foundry.py` writes one Foundry test per test case of every
`.test_cases.json` under `path/to/results`. forge-std is taken from
`$FORGE_STD`, or from the `forge-std/` folder that `install.sh` clones next
to this repo. A negative test is confirmed when forge stops with
`panic: assertion failed (0x01)`; a positive test is confirmed when the call
passes.

```bash
python3 script/witnesses2foundry.py --coverage cov_dir path/to/results
cd cov_dir && forge coverage --offline --match-path 'test/*' --no-match-coverage 'test/' --report summary --report lcov
```

`--coverage` wraps every call in try/catch, so a failing assert does not stop
the coverage run. Paths that revert before any assert (for example a
`require` that fails) do not become tests, so their branches stay uncovered.
