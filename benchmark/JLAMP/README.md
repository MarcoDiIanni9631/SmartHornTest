# Contracts of the JLAMP paper

The six contracts of the experimental evaluation of the gas-aware testing
paper, with the function under analysis. All of them go through the SolCMC
route.

| folder | function |
|---|---|
| `AuctionOffer/` | `offer` |
| `LotteryFaulty/` | `enter` |
| `OperationFaulty/` | `positiveDifference` |
| `OwnableFaulty/` | `unsafeSetOwner` |
| `PaymentPlan/` | `withdraw` |
| `BootVesting/` | `claimable` |

Each folder has the contract as in the paper (`.sol`) and the run in
`with_vgood/`: each condition of a `require` becomes its own `require`, with
an `assert` of the same condition before it, so the tool also finds the tests
that violate that condition, and
a marker assert is added at the end of the function (`vgood`), so the tool
also finds positive tests (runs that reach the end of the function).

The run folder has the contract analyzed (`.sol`), the CHCs and the test
cases (`.test_cases.json`).

Each assert is analyzed on its own (one interpreter run per assert, in
parallel), as SolCMC does with one query per assert.
Options: `--maxdepth 400`, timeout 7200 s.

| contract | neg / pos | analysis |
|---|---|---|
| AuctionOffer | 3 / 1 | all paths explored |
| LotteryFaulty | 1 / 1 | all paths explored |
| OperationFaulty | 5 / 2 | all paths explored |
| OwnableFaulty | 2 / 1 | all paths explored |
| PaymentPlan | 6 / 5 | timeout |
| BootVesting | 4 / 6 | timeout |
