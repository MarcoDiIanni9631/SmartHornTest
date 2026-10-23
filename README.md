# SmartHornTest

**Test generation for Solidity smart contracts from Constrained Horn Clauses (CHCs), with SWI-Prolog, CLP(Q) and Z3.**

SmartHornTest translates a Solidity contract into CHCs and explores them with a
CLP(Q)+Z3 interpreter. Every path it finds becomes a test case: concrete input
values plus the constraints on the inputs that lead to that path, written with
the Solidity names. The test cases are then turned into Foundry tests and run
on the original contract.

- **Negative test**: a path where an `assert` of the contract fails.
- **Positive test**: a path that ends without breaking any `assert`.

There are two ways to get the CHCs from the contract, called *routes*:

- **yul2chc**: Solidity is compiled to Yul by [grey](https://github.com/MarcoDiIanni9631/grey),
  then [yul-chc](https://github.com/MarcoDiIanni9631/yul-chc) translates the Yul code into CHCs.
  It analyses one function at a time.
- **SolCMC**: the CHCs are the ones written by the solc model checker
  (`--model-checker-print-query`), converted to Prolog with VeriMAP.
  It analyses every public function, one transaction after the constructor.

The interpreter is the same for both routes.

---

## Quick start

```bash
bash smarthorntest_completo.sh path/to/MyContract.sol -f myFunction
```

This runs the whole process on one contract:

1. adds the `vgood` marker, so that positive tests are found too;
2. the yul2chc route (function `myFunction`);
3. the SolCMC route (all functions);
4. Foundry: every test case becomes a Foundry test and runs on the **original** contract;
5. `forge coverage` of the generated tests.

Everything is written to `path/to/MyContract_completo/`:

| Path | Contents |
|---|---|
| `comandi.txt` | every command that was run, in order (each line can be run again on its own) |
| `originale/` | the contract as it was given |
| `MyContract.sol` | the contract with the `vgood` marker (the one analysed) |
| `yul/`, `solcmc/` | the results of the two routes (`.zmiout`, `.test_cases.json`, ...) |
| `foundry_yul/`, `foundry_solcmc/` | Foundry projects: `test/*.t.sol` and `forge.json` (the output of `forge test --json`) |
| `coverage_yul.txt`, `coverage_solcmc.txt` | the output of `forge coverage` |

Options (all optional):

| Option | Meaning |
|---|---|
| `-f NAME` | function to analyse on the yul2chc route (default: the first one) |
| `-t SEC` | interpreter timeout |
| `-d N` | maxdepth (maximum number of resolution steps) |
| `-s yul` or `-s solcmc` | run only one route |
| `-n` | no `vgood` marker: negative tests only |

The default timeout and maxdepth are read from `smarthorntest.conf`.
`bash smarthorntest_completo.sh -h` prints the help.

### Reading the results

- A **negative** test is *confirmed* when Foundry stops with
  `panic: assertion failed (0x01)`: the assert really fails with those values.
- A **positive** test is *confirmed* when the call passes without errors.
- Foundry only runs the generated tests. It does not verify the contract: a
  confirmed test tells that the test does what it claims, nothing more.
- Paths that revert before reaching any assert (for example a `require` that
  fails) do not become tests. Their branches stay uncovered in `forge coverage`.

---

## Requirements

Installed by `script/install.sh`:

| Tool | Notes |
|---|---|
| [grey](https://github.com/MarcoDiIanni9631/grey) | Solidity to Yul (bundles its own `solc`) |
| [yul-chc](https://github.com/MarcoDiIanni9631/yul-chc) | Yul to CHCs, plus the transformer |
| [swi-prolog-z3](https://github.com/MarcoDiIanni9631/swi-prolog-z3) | SWI-Prolog / Z3 bridge (compiled by the script) |
| [Z3](https://github.com/Z3Prover/z3) 4.15 | SMT solver (prebuilt release) |
| [forge-std](https://github.com/foundry-rs/forge-std) | standard library for the Foundry tests |

Needed before running the script:

| Tool | Needed for |
|---|---|
| [SWI-Prolog](https://www.swi-prolog.org/Download.html) 9.2+ (`swipl`, `swipl-ld`) | the interpreter |
| Python 3.8+ with `z3-solver` (`pip install z3-solver`) | the pipeline scripts and the projected constraints |
| `git`, `gcc`, `unzip`, `rsync`, `curl` or `wget` | the installation |
| [solc](https://github.com/ethereum/solidity/releases) on the `PATH` | the SolCMC route |
| VeriMAP (`scripts/smt2map`), in `../verimap` or in `$VERIMAP` | the SolCMC route |
| [Foundry](https://getfoundry.sh) (`forge`) | the Foundry tests and the coverage |
| [CHCViz](https://github.com/MarcoDiIanni9631/CHCViz) as `chcviz` on the `PATH` | only the CHC graph (`--graph`, `--highlight`) |
| [Slither](https://github.com/crytic/slither) | only the Solidity CFG (`step10_sol_cfg.sh`) |

> **Note:** `grey` and `yul-chc` above point to forks, not the original
> `costa-group/grey` and `chc-lab/yul-chc`. The public versions of these two
> projects do not work together out of the box (the JSON that `grey` produces
> and the JSON that `yul-chc` expects do not match, and `yul-chc` is missing
> one file). The forks fix both problems and are the versions this pipeline
> is tested against.

---

## Installation

**1. Clone this repo**
```bash
git clone --depth 1 https://github.com/MarcoDiIanni9631/SmartHornTest.git swipl_z3_clpq_interpreter
cd swipl_z3_clpq_interpreter
```

**2. Run the install script**
```bash
bash script/install.sh
```
It clones `grey`, `yul-chc`, `swi-prolog-z3` and `forge-std` next to this
repo, gets a ready-to-use Z3 build and compiles the SWI-Prolog/Z3 bridge.
It does not install system packages (no `sudo`). At the end it prints
`BRIDGE OK`, then checks the tools it does not install and says what is
missing and which part of the pipeline needs it.

**3. Try it on a contract**
```bash
bash smarthorntest_completo.sh path/to/MyContract.sol -f myFunction
```

### If something goes wrong

If `swipl` is installed but not on your `PATH` (for example, you built it
from source into a custom folder), set `SWIPL_BIN` before running the script:
```bash
export SWIPL_BIN=/path/to/your/swipl
bash script/install.sh
```

The default Z3 download is built for Linux x86_64 with glibc 2.39 or newer.
On an older system the script uses the Z3 library of the `z3-solver` Python
package instead (so install `z3-solver` first). On a machine that is not
Linux x86_64, get the right build from the
[Z3 releases page](https://github.com/Z3Prover/z3/releases) and point the script at it:
```bash
ARCHIVE_URL=https://github.com/Z3Prover/z3/releases/download/z3-4.15.2/<your-build>.zip bash script/install.sh
```
Or, if you already have Z3 installed somewhere (for example built from source), skip the download:
```bash
SKIP_Z3=1 Z3_INCLUDE=/path/to/z3/include Z3_LIB_DIR=/path/to/z3/lib bash script/install.sh
```

### How the paths work (`script/config.sh`)

Every pipeline script reads its paths from `script/config.sh`. By default it
assumes this layout, which is the one `script/install.sh` sets up:

```
<parent folder>/
  swipl_z3_clpq_interpreter/   <- this repo
  grey/
  yul-chc/
  swi-prolog-z3/
  z3/
  forge-std/
  verimap/                     <- only for the SolCMC route, not cloned by install.sh
```

You can override any of these with an environment variable, without touching any file:

```bash
export GREY_DIR=/somewhere/else/grey
export YULCHC_DIR=/somewhere/else/yul-chc
export SWIZ3_TURIBE_PATH=/somewhere/else/swi-prolog-z3
export SWIPL_BIN=/somewhere/else/swipl
export Z3_LIB_DIR=/somewhere/else/z3/lib
export FORGE_STD=/somewhere/else/forge-std
export VERIMAP=/somewhere/else/verimap
```

---

## The two routes

```
                    Solidity contract (.sol)
                              │
                 add_vgood.py (positive tests)
                              │
         ┌────────────────────┴────────────────────┐
         │ yul2chc                                 │ SolCMC
         │ grey: .sol -> Yul (.json)               │ solc --model-checker-print-query (.smt2)
         │ yul-chc: Yul -> CHCs (.pl)              │ solcmc_assume_asserts.py
         │ transform (.t.pl)                       │ VeriMAP smt2map (.smt2.pl)
         │ yulPl2Constr.py (.t_constr.pl)          │ smt2pl_to_constr.pl --single-tx (.chc.pl)
         └────────────────────┬────────────────────┘
                              │
            InterpreterAnalysis5.2.sh: CLP(Q)+Z3 interpreter
            (target incorrect for yul2chc, ff for SolCMC)
                              │
                           .zmiout
                              │
         zmiout2json.py (yul2chc) / solcmc_zmiout2json.py (SolCMC)
                              │
                     .test_cases.json
                              │
            witnesses2foundry.py -> forge test, forge coverage
```

The `.zmiout` file name tells the outcome: `derivable` means that at least one
test was found, `nonDerivable` that no path reaches the target within the
given maxdepth and timeout.

### The `vgood` marker

`script/add_vgood.py` adds `uint256 vgood = 42;` at the start of every function
and `vgood = 1042; assert(vgood < 20);` before every `return` and at the end.
That assert fails exactly on the paths that pass every real assert, so the
interpreter finds those paths too. A test whose model holds the value 1042 is
positive; the others are negative. The Foundry tests always run on the
contract without the marker.

---

## The yul2chc route alone: `sol2analysis.sh`

```bash
nohup bash script/sol2analysis.sh --gen-aux --aux-hint _myFunction_ \
  --maxdepth 100 --timeout 600 --varz3 --varclpq \
  path/to/MyContract/MyContract.sol incorrect &
```

All output files are written to the same folder as the `.sol`.
`--gen-aux` writes the entry point (`.aux.pl`) automatically; `--aux-hint`
picks the function when the contract has more than one.

| Flag | Meaning |
|---|---|
| `--until-tpl` | stop after the conversion (no analysis) |
| `--skip-convert` | skip the conversion (use the existing `.t_constr.pl`) |
| `--gen-aux` | write the `.aux.pl` entry point automatically |
| `--aux-hint NAME` | function to analyse, used by `--gen-aux` |
| `--timeout SEC` | interpreter timeout in seconds |
| `--maxdepth N` | maximum number of resolution steps |
| `--varz3` | write `.vars_z3.txt` with the constraints projected by Z3 |
| `--varclpq` | write `.vars_clpq.txt` with the constraints projected by CLP(Q) |
| `--annotate` | write `.annotated.sol` with the constraints as a comment |
| `--graph` | draw the CHC dependency graph in SVG (needs CHCViz) |
| `--highlight` | highlight the path of each test on the CHC graph (implies `--graph`) |
| `--skip-existing` | skip the analysis if a `.zmiout` already exists |

`smarthorntest.sh` is a shorter launcher for the same route: it reads its
defaults from `smarthorntest.conf` and runs in the background
(`bash smarthorntest.sh -h` for the help).

### Output files of the yul2chc route

| File | Produced by | Contents |
|---|---|---|
| `Contract.json` | grey | Yul intermediate representation |
| `Contract.pl` | yul-chc | raw CHC clauses |
| `Contract.aux.pl` | sol2tpl.py | function entry point |
| `Contract.t.pl` | transform | transformed CHC clauses |
| `Contract.t.pl-defs.txt` | transform | predicate definitions (needed by the vars scripts) |
| `Contract.t_constr.pl` | yulPl2Constr.py | CHC clauses with CLP(Q) constraints |
| `Contract.t_constr.pl.*.zmiout` | InterpreterAnalysis5.2.sh | analysis output |
| `...zmiout.vars_z3.txt` | zmiout2vars_z3.py | test values and projected constraints (Z3) |
| `...zmiout.vars_clpq.txt` | zmiout2vars_clpq.py | test values and projected constraints (CLP(Q)) |
| `Contract.test_cases.json` | zmiout2json.py | test cases (see below) |
| `Contract.annotated.sol` | annotate_sol.py | original `.sol` with the constraints as a comment |
| `dot_dias/*.svg` | chcviz | CHC dependency graph |
| `dot_dias/*_testN_<kind>_highlighted.{dot.svg,html}` | zmiout2dot_highlight.py / dot2html.py | CHC graph with the path of test N highlighted |
| `dot_dias/*_alltests_index.html` | step9_highlight.sh | index of all the highlighted graphs |
| `dot_dias/sol_cfg/*.html` | step10_sol_cfg.sh | Solidity CFG per function (via Slither), linked to the CHC graph |

The SolCMC route writes `Contract.smt2`, `Contract.smt2.pl`, `Contract.chc.pl`,
the `.zmiout` and `Contract.test_cases.json`. Its single steps are in
[`docs/COMMANDS.md`](docs/COMMANDS.md).

---

## The test cases: `.test_cases.json`

Both routes write the same format. This is the first test of the
`Bonus` example (`addBonus(uint256 points)`, yul2chc route):

```json
{
  "contractName": "Bonus",
  "stateVariables": [],
  "functions": [{
    "signature": "addBonus(uint256)",
    "params": ["points"],
    "test_cases": [{
      "id": 1,
      "kind": "positive",
      "concrete_values": ["points == 11"],
      "constraints_z3": ["points >= 11"],
      "constraints_clpq": ["points>10"],
      "constraints_z3_start": ["points >= 11"],
      "constraints_clpq_start": ["points>10"]
    }]
  }]
}
```

- `kind`: `negative` (an assert fails) or `positive` (no assert fails).
- `concrete_values`: the values chosen by Z3 for the parameters and the state variables.
- `constraints_z3`, `constraints_clpq`: the constraints of the path, projected
  on the Solidity names by Z3 (quantifier elimination) and by CLP(Q) (`dump/3`).
  The state variables are taken where the path ends.
- `constraints_z3_start`, `constraints_clpq_start`: the same, with the state
  variables taken when the call starts.
- The SolCMC route also writes `error_code` (the error number of solc) and
  `failed_assert` (the condition of the failed assert, when it is known).

---

## Single steps

To try or debug one step at a time (both routes, the `vgood` marker, Foundry
and coverage), see [`docs/COMMANDS.md`](docs/COMMANDS.md).

---

## Acknowledgments

This project is partially supported by the PNRR project FAIR (Future AI Research, PE00000013),
Spoke 9 (Green-aware AI), under the NRRP MUR program funded by the NextGenerationEU.
