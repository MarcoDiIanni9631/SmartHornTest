// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simplified from Splitter_asm_faulty.sol
// Removed: address payees, shares, receive(), release(), totalShares, totalReleased
// Kept: assembly loop computing sumPend with BUG (uses amount instead of pending)
//
// BUG: sumPend := add(sumPend, amount) should be sumPend := add(sumPend, pend)
// where pend = amount - released.
// This makes sumPend larger than actual pending, so
// assert(sumPend <= (amountp0-released0) + (amountp1-released1) + (amountp2-released2))
// can fail even when the real pending total would be fine.

contract SplitterFaulty {
    uint256 public amountp0;
    uint256 public amountp1;
    uint256 public amountp2;

    uint256 public released0;
    uint256 public released1;
    uint256 public released2;

    function releasable(uint256 a0, uint256 a1, uint256 a2, uint256 r0, uint256 r1, uint256 r2) public {
        require(a0 >= r0 && a1 >= r1 && a2 >= r2);

        amountp0 = a0; amountp1 = a1; amountp2 = a2;
        released0 = r0; released1 = r1; released2 = r2;

        uint256 sumPend;

        assembly {
            for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                let amount := sload(i)           // slots 0,1,2 = amountp0/1/2
                let rel    := sload(add(3, i))   // slots 3,4,5 = released0/1/2
                let pend   := sub(amount, rel)
                // BUG: accumulates amount instead of pend
                sumPend := add(sumPend, amount)
            }
        }

        uint256 totalPending = (amountp0 - released0) + (amountp1 - released1) + (amountp2 - released2);
        assert(sumPend <= totalPending);
    }
}
