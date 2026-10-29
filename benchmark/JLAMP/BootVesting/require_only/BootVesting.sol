// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Simplified from Boot Finance Vesting.sol, function _claimableAmount
// (Web3Bugs, contracts/51; Code4rena 2021-11, finding H-08).
// Each vesting gives AMOUNT tokens over YEAR time units.
contract BootVesting {
    uint256 constant YEAR = 100;
    uint256 constant AMOUNT = 100;

    uint256 public vestedFull;
    uint256 public vestedPartial;

    function claimable(uint256 n, uint256 currentTime,
                       uint256 start0, uint256 start1) public {
        assert(n >= 1);  // added: fails when the require below fails
        require(n >= 1);
        assert(n <= 2);  // added: fails when the require below fails
        require(n <= 2);
        assert(currentTime > start0);  // added: fails when the require below fails
        require(currentTime > start0);
        assert(currentTime > start1);  // added: fails when the require below fails
        require(currentTime > start1);

        uint256 completely_vested = 0;
        uint256 partial_sum = 0;
        uint256 sumTotal = 0;
        uint256 iTimeStamp = start0;
        for (uint256 i = 0; i < n; i++) {
            sumTotal = sumTotal + AMOUNT;
            if (currentTime >= iTimeStamp + YEAR) {
                // vesting over: all the amount
                completely_vested = completely_vested + AMOUNT;
            } else {
                // vesting not over: the part for the time passed
                uint256 part = currentTime - iTimeStamp;
                partial_sum = partial_sum + part;
            }
            iTimeStamp = start1;
        }
        vestedFull = vestedFull + completely_vested;
        vestedPartial = partial_sum;
        uint256 s = vestedFull + partial_sum;

        assert(s <= sumTotal);

    }
}
