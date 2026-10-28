# Experiments

Benchmark and results of the evaluation of SmartHornTest (PhD thesis of Marco
Di Ianni, Chapter 6).

| folder | origin | contracts | with a bug |
|---|---|---|---|
| `soltg/` | regression benchmark of SolTG | 72 | 25 |
| `smtchecker/` | SMTChecker tests of the Solidity compiler | 150 | 55 |

Each file has one contract and at least one assertion in a public function;
contracts with mappings, arrays, structs, inline assembly, external calls or
`address(this).balance` are left out, as well as those whose bug needs more
than one call (the tools run one call at a time). The code is the same as in
the two benchmarks; in the SMTChecker files only the comment at the end, with
the expected answer, was produced again with solc 0.8.29.

Each contract has a folder with the contract (`<name>.sol`), the same contract
with the `vgood` assertion used to get the positive tests (`<name>_vgood.sol`),
and the test cases found with the two routes (`solcmc.test_cases.json`,
`yul2chc.test_cases.json`).

`summary.csv` has one row per contract: the expected answer, the outcome of
SmartHornTest (both routes), Mythril and Manticore, and the number of tests
found.

`foundry.csv` has one row per test case: the route, the values, the result of
`forge test` on the original contract (without `vgood`) and whether the test
case is confirmed (a negative test case fails with `panic: assertion failed
(0x01)`, a positive one passes).

`report.html` shows the same results as pie charts: click a slice to see its
contracts, and a contract to see its test cases and its source code (open it
in a browser; it is built by `script/build_report_html.py`).

## How to run again

Depth bound 100, timeout 600 s, one call at a time, solc 0.8.29, SWI-Prolog
9.3.31, Z3 4.15.3.

All the contracts, then the Foundry tests and the coverage (several hours):

    bash experiments/run_all.sh

One contract:

    ./smarthorntest.sh experiments/soltg/sanity/simple_if/simple_if_vgood.sol -r solcmc -d 100 -t 600
