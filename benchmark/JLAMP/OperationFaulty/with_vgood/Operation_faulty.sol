// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Operation {
    function positiveDifference(uint256 x, uint256 y) public pure returns (int256) { uint256 vgood = 42;
      assert(x > 0);  // added: fails when the require below fails
      require(x > 0,"Input must be non-zero");
      assert(y > 0);  // added: fails when the require below fails
      require(y > 0, "Input must be non-zero");
      assert(x != y);  // added: fails when the require below fails
      require(x != y, "Inputs must be different");

        int256 diff;
        
        // was inline assembly: sub wraps around, so unchecked
        unchecked {
            if (x > y) { //bug: y - x insted of x - y
                diff = int256(y - x);
            } else {
                diff = int256(y - x);
            }
        }

        assert(diff > 0);

        { vgood = 1042; assert(vgood < 20); return diff; }
    vgood = 1042; assert(vgood < 20);
    }
}
