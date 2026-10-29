# Contracts of the JLAMP paper

The six contracts of the experimental evaluation of the gas-aware testing
paper, with the function under analysis and the route used:

| folder | function | route |
|---|---|---|
| `AuctionOffer/` | `offer` | SolCMC |
| `LotteryFaulty/` | `enter` | SolCMC |
| `OperationFaulty/` | `positiveDifference` | yul2chc |
| `OwnableFaulty/` | `unsafeSetOwner` | yul2chc |
| `PaymentPlan/` | `withdraw` | SolCMC |
| `BootVesting/` | `claimable` | SolCMC |

OperationFaulty and OwnableFaulty use inline assembly, which SolCMC does not
model, so they go through yul2chc.

Each folder has the contract as in the paper (`.sol`) and two runs:

- `require_only/`: an `assert` is added before each `require`, with the same
  condition, so the tool also finds the tests that violate the `require`.
  All tests are negative.
- `with_vgood/`: as above, plus a marker assert at the end of the function
  (`vgood`), so the tool also finds positive tests (runs that reach the end
  of the function).

Each run folder has the contract analyzed (`.sol`), the CHCs, the
interpreter output (`.zmiout`, its name says how the analysis ended), the
test cases (`.test_cases.json`), the Foundry test (`.t.sol`) and its output
(`forge_test.txt`). Foundry runs on the contract with the added asserts and
without `vgood`: a negative test must fail with `panic 0x01`, a positive
test must pass. All tests are confirmed.

Options: `--maxdepth 400`, timeout 300 s, and 7200 s for PaymentPlan and
BootVesting (loops).

| contract | require_only (neg) | with_vgood (neg / pos) | analysis |
|---|---|---|---|
| AuctionOffer | 3 | 3 / 1 | all paths explored |
| LotteryFaulty | 1 | 1 / 1 | all paths explored |
| OperationFaulty | 4 | 4 / 1 | all paths explored |
| OwnableFaulty | 2 | 2 / 1 | all paths explored |
| PaymentPlan | 6 | 6 / 5 | timeout |
| BootVesting | 4 | 4 / 6 | timeout |
