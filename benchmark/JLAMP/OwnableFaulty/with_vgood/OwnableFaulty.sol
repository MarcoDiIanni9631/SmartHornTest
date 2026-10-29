// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Simplified version of Ownable_faulty.sol (TPLP).
// BUG: unsafeSetOwner stores a bytes32 directly to the owner slot
//      without masking the upper 96 bits.
//      assert(owner_value <= type(uint160).max) fails when newOwner
//      has bits above position 160 set.
// Z3 finds: newOwner = 2^161 --> owner_value > uint160.max --> assert fails.
contract OwnableFaulty {

    uint256 private _owner;
    uint256 constant MAX_ADDRESS = 2**160 - 1;

    function unsafeSetOwner(uint256 newOwner) public { uint256 vgood = 42;
        assert(newOwner != 0);  // added: fails when the require below fails
        require(newOwner != 0);

        uint256 owner_value;
        assembly {
            sstore(_owner.slot, newOwner)
            owner_value := sload(_owner.slot)
        }

        assert(owner_value <= MAX_ADDRESS);
    vgood = 1042; assert(vgood < 20);
    }
}
