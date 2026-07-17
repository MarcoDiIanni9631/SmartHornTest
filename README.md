# SmartHornTest

**Automated test-case generation for Solidity smart contracts via Constrained Horn Clauses (CHC), SWI-Prolog, and Z3.**

SmartHornTest compiles a Solidity contract into CHC clauses, interprets them with a CLP(Q)+Z3 engine, and — when a property violation is found — automatically generates concrete witness values (counterexamples) mapped back to Solidity variables.

---

## Requirements

| Tool | Tested version | Notes |
|---|---|---|
| [SWI-Prolog](https://www.swi-prolog.org/Download.html) | 9.2+ | Core interpreter |
| [Z3](https://github.com/Z3Prover/z3) | 4.15.2 | SMT solver |
| Python | 3.8+ | Pipeline scripts |
| [grey](https://github.com/MarcoDiIanni9631/grey) | — | Solidity → YUL compiler |
| [yul-chc](https://github.com/MarcoDiIanni9631/yul-chc) | — | YUL → CHC translator + transformer |
| [swi-prolog-z3](https://github.com/MarcoDiIanni9631/swi-prolog-z3) | — | SWI-Prolog / Z3 bridge |

All of the above must be installed and available before running the pipeline.
The `solc` Solidity compiler is also required and is bundled inside grey.

> **Note:** `grey` and `yul-chc` above point to forks, not the original
> `costa-group/grey` and `chc-lab/yul-chc`. The public versions of these two
> projects do not work together out of the box (the JSON that `grey` produces
> and the JSON that `yul-chc` expects do not match, and `yul-chc` is missing
> one file). The forks fix both problems and are the versions this pipeline
> is tested against.

---

## Installation

This section explains how to set up everything this repo needs on a new
machine (a new server, a laptop, anywhere).

### 1. Install the basic tools

You need: `git`, `python3`, SWI-Prolog (`swipl` and `swipl-ld`), a C compiler
(`gcc`), `unzip`, `rsync`, and `curl` or `wget`.

On Ubuntu/Debian:
```bash
sudo apt install git python3 swi-prolog build-essential unzip rsync curl
```

If you don't have `sudo` access (common on shared university/lab servers),
ask whoever manages the server to install these, or check if they are
already installed with `which swipl swipl-ld git python3 gcc unzip rsync`.

### 2. Clone this repo

```bash
git clone https://github.com/MarcoDiIanni9631/SmartHornTest.git swipl_z3_clpq_interpreter
cd swipl_z3_clpq_interpreter
```

### 3. Run the install script

```bash
bash script/install.sh
```

This script:
- clones `grey`, `yul-chc`, and `swi-prolog-z3` as folders next to this repo
  (it skips this step if a folder is already there, so it is safe to run
  more than once),
- downloads a ready-to-use Z3 build (no need to compile Z3 from source),
- compiles the SWI-Prolog/Z3 bridge (`z3_swi_foreign.so`),
- runs a quick test to check the bridge loads correctly.

If it ends with `BRIDGE OK` and `Setup complete.`, the installation worked.

If `swipl` is installed but not on your `PATH` (for example, you built it
from source into a custom folder), set `SWIPL_BIN` before running the
script:
```bash
export SWIPL_BIN=/path/to/your/swipl
bash script/install.sh
```

If your machine is not Linux x86_64, the default Z3 download will not work.
Get the right build from the [Z3 releases page](https://github.com/Z3Prover/z3/releases)
and point the script at it:
```bash
ARCHIVE_URL=https://github.com/Z3Prover/z3/releases/download/z3-4.15.2/<your-build>.zip bash script/install.sh
```
Or, if you already have Z3 installed somewhere, skip the download entirely:
```bash
SKIP_Z3=1 Z3_INCLUDE=/path/to/z3/include Z3_LIB_DIR=/path/to/z3/lib bash script/install.sh
```

### 4. Try it on a contract

```bash
bash script/sol2analysis.sh --gen-aux --stop-first-per-loop --timeout 300 \
  --varz3 --varclpq --annotate \
  path/to/YourContract.sol incorrect
```

This produces `YourContract.test_cases.json` in the same folder as the
`.sol` file.

### How the paths work (`script/config.sh`)

Every pipeline script (`step1_grey.sh`, `step2_yul2chc.sh`,
`step3_transform.sh`, `InterpreterAnalysis5.2.sh`) reads its paths from
`script/config.sh`. By default it assumes this layout:

```
<parent folder>/
  swipl_z3_clpq_interpreter/   <- this repo
  grey/
  yul-chc/
  swi-prolog-z3/
  z3/
```

which is exactly what `script/install.sh` sets up. You can override any of
these with an environment variable, without touching any file:

```bash
export GREY_DIR=/somewhere/else/grey
export YULCHC_DIR=/somewhere/else/yul-chc
export SWIZ3_TURIBE_PATH=/somewhere/else/swi-prolog-z3
export SWIPL_BIN=/somewhere/else/swipl
export Z3_LIB_DIR=/somewhere/else/z3/lib
```

---

## All-in-one script: `sol2analysis.sh`

**This is the main script.** It runs the entire pipeline automatically:
conversion → analysis → variable mapping → annotated .sol → CHC graph.

```bash
nohup bash script/sol2analysis.sh \
  --gen-aux \
  --stop-first-per-loop \
  --timeout 300 \
  --varz3 \
  --varclpq \
  --annotate \
  --graph \
  test/MyContract/MyContract.sol \
  incorrect &
```

> Run with `nohup ... &` so it keeps running even if the terminal closes.
> All output files are written to the same folder as the `.sol`.

> **Important:** always include `--gen-aux` unless you have already manually created the `.aux.pl` file. Without it, the pipeline will fail at step 3 with `aux.pl non trovato`. If the contract has multiple public functions, also add `--aux-hint <functionName>` to tell the script which one to analyse.

**Available flags:**

| Flag | Meaning |
|---|---|
| `--until-tpl` | Stop after conversion (no analysis) |
| `--stop-first-per-loop` | One counterexample per loop iteration (recommended) |
| `--stop-first` | Stop at the very first counterexample |
| `--timeout SEC` | Analysis timeout in seconds (default: 60000) |
| `--maxdepth N` | Maximum unfolding depth (default: 10000000) |
| `--looplimit N` | Maximum number of loop iterations |
| `--varz3` | Generate `.vars_z3.txt` with Z3 projected constraints |
| `--varclpq` | Generate `.vars_clpq.txt` with CLP(Q) projected constraints |
| `--varsmt` | Generate `.vars_smt.txt` with SMT-LIB projected constraints |
| `--annotate` | Generate `.annotated.sol` with constraints as comment |
| `--graph` | Generate CHC dependency graph in SVG (via chcviz) |
| `--skip-existing` | Skip if a .zmiout already exists |

---

## Pipeline Overview

```
 Solidity contract (.sol)
        │
        │  STEP 1 — sol2tpl.py
        │  (GREY + yul2chc + transform)
        ▼
 .json  .pl  .aux.pl  .t.pl  .t.pl-defs.txt
        │
        │  STEP 2 — yulPl2Constr.py
        ▼
 .t_constr.pl
        │
        │  STEP 3 — InterpreterAnalysis5.2.sh
        │  (CLP(Q) + Z3 interpreter)
        ▼
 .zmiout   (derivable = violation found / nonDerivable = no violation)
        │
        │  STEP 4 — zmiout2vars_z3.py / zmiout2vars_clpq.py
        ▼
 .vars_z3.txt  /  .vars_clpq.txt
        │
        │  STEP 5 — zmiout2json.py
        ▼
 .test_cases.json  (structured test cases with concrete values + projected constraints)
        │
        │  STEP 6 — annotate_sol.py
        ▼
 .annotated.sol   (original source + projected constraints as comment)
```

---

## Output Files Reference

| File | Produced by | Contents |
|---|---|---|
| `Contract.json` | GREY | YUL intermediate representation |
| `Contract.pl` | yul2chc | Raw CHC clauses |
| `Contract.aux.pl` | sol2tpl.py | Function entry point |
| `Contract.t.pl` | transform | Transformed CHC clauses |
| `Contract.t.pl-defs.txt` | transform | Predicate definitions (needed by vars scripts) |
| `Contract.t_constr.pl` | yulPl2Constr.py | CHC clauses with CLP(Q) constraints |
| `Contract.t_constr.pl.*.zmiout` | InterpreterAnalysis5.2.sh | Analysis output |
| `...zmiout.vars_z3.txt` | zmiout2vars_z3.py | Witness values + projected constraints (Z3) |
| `...zmiout.vars_clpq.txt` | zmiout2vars_clpq.py | Witness values + projected constraints (CLP(Q)) |
| `Contract.test_cases.json` | zmiout2json.py | Structured test cases (concrete values + Z3/CLP(Q) constraints) |
| `Contract.annotated.sol` | annotate_sol.py | Original .sol with constraints appended as comment |
| `dot_dias/*.svg` | chcviz | CHC dependency graph |

---

## Generating JSON test cases: `zmiout2json.py`

After the analysis produces a `.zmiout` file, run this script to generate a structured `.test_cases.json` with concrete witness values and projected constraints for each test case found.

```bash
python3 script/zmiout2json.py \
  path/to/Contract.sol \
  path/to/Contract.t.pl-defs.txt \
  path/to/Contract.zmiout
```

The output file `Contract.test_cases.json` is written to the same folder as the `.zmiout`. Example structure:

```json
{
  "stateVariables": ["bid", "cash"],
  "functions": [{
    "signature": "offer(uint,uint)",
    "params": ["newBid", "payment"],
    "test_cases": [{
      "id": 1,
      "kind": "negative",
      "concrete_values": ["newBid == 2", "payment == 1", "bid == 0", "cash == 0"],
      "constraints_z3": ["bid == 1*newBid", "cash == 1*payment", "newBid - payment >= 1"],
      "constraints_clpq": ["bid=newBid", "cash=payment", "newBid-payment>0"]
    }]
  }]
}
```

- `kind`: `"negative"` = counterexample (assertion violation), `"positive"` = safe witness path.
- `concrete_values`: exact values assigned by Z3 to Solidity variables.
- `constraints_z3`: constraints projected onto Solidity variables via Z3 quantifier elimination.
- `constraints_clpq`: same projection via SWI-Prolog CLP(Q) `dump/3`.

**Requirements:** Python 3, `z3-solver` (`pip install z3-solver`), SWI-Prolog with CLP(Q) library.

---

## Individual pipeline steps

For experimenting with or debugging a single stage, see [`docs/COMMANDS.md`](docs/COMMANDS.md) — it has ready-to-run commands for each step with concrete examples.

---

## Acknowledgments

This project is partially supported by the PNRR project FAIR — Future AI Research (PE00000013),
Spoke 9 — Green-aware AI, under the NRRP MUR program funded by the NextGenerationEU.
