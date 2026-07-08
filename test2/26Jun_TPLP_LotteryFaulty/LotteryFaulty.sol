// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simplified from lottery_yul_incorrect.sol
//
// Original slot layout (Lottery inherits Ownable):
//   slot 0: _owner       (address) ← assembly reads this thinking it is playerCount
//   slot 1: playerCount  (uint256)
//   slot 2: players[0]   (address)
//
// Bug in enter(): assembly increments slot 0 (_owner) instead of slot 1 (playerCount).
// players[0] (lastPlayer) is never written.
// assert(players[playerCount - 1] == msg.sender) fails:
//   playerCount = 0 → assertion on uninitialized slot → always fails.
//
// This version preserves the same slot layout and bug using plain uint256 variables.
// Z3 finds: newPlayer = 1, owner = 1, playerCount = 0, lastPlayer = 0
//           → assert(0 == 1) fails.
contract LotteryFaulty {
    uint256 public owner;        // slot 0 — mirrors Ownable._owner
    uint256 public playerCount;  // slot 1 — never updated due to slot bug
    uint256 public lastPlayer;   // slot 2 — never written

    function enter(uint256 newPlayer) public {
        require(newPlayer > 0);
        require(playerCount < 300);

        // BUG: slot 0 (owner) incremented instead of slot 1 (playerCount)
        owner = owner + 1;
        // lastPlayer never written (would land at wrong slot in original assembly)

        assert(lastPlayer == newPlayer);
    }
}
