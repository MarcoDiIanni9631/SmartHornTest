# Experiments

Benchmark and results of the evaluation of SmartHornTest (PhD thesis of Marco
Di Ianni, Chapter 6).

| folder | origin | contracts | with a bug |
|---|---|---|---|
| `soltg/` | regression benchmark of SolTG | 81 | 30 |
| `smtchecker/` | SMTChecker tests of the Solidity compiler | 151 | 56 |

Each contract has a folder with the contract (`<name>.sol`), the same contract
with the `vgood` assertion used to get the positive tests (`<name>_vgood.sol`),
and the test cases found with the two routes (`solcmc.test_cases.json`,
`yul2chc.test_cases.json`).

`summary.csv` has one row per contract: the expected answer, the outcome of
SmartHornTest (both routes), Mythril and Manticore, and the number of tests
found.

## How to run again

Depth bound 100, timeout 600 s, one call at a time, solc 0.8.29, SWI-Prolog
9.3.31, Z3 4.15.3.

All the contracts, then the Foundry tests and the coverage (several hours):

    bash experiments/run_all.sh

One contract:

    ./smarthorntest.sh experiments/soltg/sanity/simple_if/simple_if_vgood.sol -r solcmc -d 100 -t 600
