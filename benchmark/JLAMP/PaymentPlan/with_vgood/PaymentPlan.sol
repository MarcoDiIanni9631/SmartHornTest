// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A user withdraws `amount`. The contract pays at most `chunk` at a time.
// Small amounts (less than one chunk) are paid at once.
// Bigger amounts are paid in installments of `chunk`, one per loop step;
// what is left at the end (less than one chunk) should be saved in `pending`.
// The bug: the part that is left is lost, it is never saved in `pending`.
// Each path has different constraints on amount and chunk, and a different
// number of storage writes (one per installment).
// Expected tests:
//   amount < chunk                -> paid at once, the check passes
//   amount = k * chunk (k = 1..4) -> k installments, nothing left, the check passes
//   k * chunk < amount < (k+1) * chunk (k = 1..3)
//                                 -> k installments, something is lost, the check fails (the bug)
contract PaymentPlan {
    uint256 public paidOut;
    uint256 public pending;

    function withdraw(uint256 amount, uint256 chunk) public { uint256 vgood = 42;
      assert(amount > 0);  // added: fails when the require below fails
      require(amount > 0);
      assert(chunk > 0);  // added: fails when the require below fails
      require(chunk > 0);
        assert(amount <= 4 * chunk);  // added: fails when the require below fails
        require(amount <= 4 * chunk);   // at most 4 installments

        if (amount < chunk) {
            paidOut = paidOut + amount;
        } else {
            uint256 left = amount;
            while (left >= chunk) {
                left = left - chunk;
                paidOut = paidOut + chunk;
            }
            // BUG: should be pending = pending + left;
        }

        assert(paidOut + pending == amount);

    vgood = 1042; assert(vgood < 20);
    }
}
