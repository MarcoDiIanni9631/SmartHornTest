# Contracts of the JLAMP paper

The six contracts of the experimental evaluation of the gas-aware testing
paper, with the function under analysis:

| folder | function |
|---|---|
| `AuctionOffer/` | `offer` |
| `LotteryFaulty/` | `enter` |
| `OperationFaulty/` | `positiveDifference` |
| `OwnableFaulty/` | `unsafeSetOwner` |
| `PaymentPlan/` | `withdraw` |
| `BootVesting/` | `claimable` |

Each folder has the contract (`.sol`), the CHCs and the test cases found by
SmartHornTest (`.test_cases.json`) and, where present, the test cases written
by hand for the `require` statements (`.manual_test_cases.json`).
