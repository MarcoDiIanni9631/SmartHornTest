// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardSystem {
    uint256 public currentBalance;

    function claimRewards(uint256 points) public {
        require(points > 0, "Points must be greater than zero");
        uint256 vgood = 42;

        if (points < 10) {
            for (uint256 i = 0; i < points; i++) {
                currentBalance += points;
            }
        } else {
            currentBalance = currentBalance + (points * 2);
        }

        assert(currentBalance < 5);

        vgood = 1042;
        assert(vgood < 20);
    }
}
