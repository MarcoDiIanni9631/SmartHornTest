// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// VGOOD version of OwnableFaulty.
// Original assert: owner_value <= type(uint160).max.
//   - Fails when newOwner has bits above position 160 set (e.g., newOwner = 2^161).
// This version finds all paths:
//   assert 1 (owner_value <= uint160.max): catches the bad path (large newOwner).
//   assert 2 (vgood < 1000): always false (vgood=1042) → positive witness
//                             (safe path: owner_value was within bounds).
contract OwnableFaulty_vgood {

    uint256 private _owner;

    function unsafeSetOwner(uint256 newOwner) public {
        require(newOwner != 0);

        uint256 owner_value;
        assembly {
            sstore(_owner.slot, newOwner)
            owner_value := sload(_owner.slot)
        }

        assert(owner_value <= type(uint160).max);

        uint256 vgood = 1042;
        assert(vgood < 1000);
    }
}
