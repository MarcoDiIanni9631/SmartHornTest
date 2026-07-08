// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// VGOOD version of Operation_faulty.
// Original assert: diff > 0.
//   - Fails when x > y (bug: computes y-x instead of x-y → diff=0).
// This version finds all paths:
//   assert 1 (diff > 0): catches the bad path (x > y → diff=0).
//   assert 2 (vgood < 1000): always false (vgood=1042) → positive witness
//                             (safe path: diff > 0 was satisfied, i.e. x < y).
contract Operation_vgood {
    function positiveDifference(uint256 x, uint256 y) public pure returns (uint256) {
        require(x > 0 && y > 0 && x != y, "Inputs must be non-zero and different");

        uint256 diff;

        assembly {
            switch gt(x, y)
            case 0 {
                diff := sub(y, x)
            }
            default { //bug: sub(y, x) instead of sub(x, y)
                diff := sub(y, x)
            }
        }

        assert(diff > 0);

        uint256 vgood = 1042;
        assert(vgood < 1000);

        return diff;
    }
}
