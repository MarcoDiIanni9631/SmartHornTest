// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// VGOOD version of LotteryFaulty.
// Original assert: lastPlayer == newPlayer.
//   - Fails due to BUG: slot 0 (owner) incremented instead of slot 1 (playerCount);
//     lastPlayer (slot 2) is never written, so lastPlayer = 0 != newPlayer when newPlayer > 0.
// This version finds all paths:
//   assert 1 (lastPlayer == newPlayer): catches the bad path (newPlayer > 0, lastPlayer stuck at 0).
//   assert 2 (vgood < 1000): always false (vgood=1042) → positive witness
//                             (safe path: newPlayer = 0 → lastPlayer(0) == newPlayer(0) → assert 1 passes).
// Note: require(newPlayer > 0) removed to allow the safe path (newPlayer = 0).
contract LotteryFaulty_vgood {
    uint256 public owner;        // slot 0 — mirrors Ownable._owner
    uint256 public playerCount;  // slot 1 — never updated due to slot bug
    uint256 public lastPlayer;   // slot 2 — never written

    function enter(uint256 newPlayer) public {
        require(playerCount < 300);

        // BUG: slot 0 (owner) incremented instead of slot 1 (playerCount)
        owner = owner + 1;
        // lastPlayer never written (would land at wrong slot in original assembly)

        assert(lastPlayer == newPlayer);

        uint256 vgood = 1042;
        assert(vgood < 1000);
    }
}
