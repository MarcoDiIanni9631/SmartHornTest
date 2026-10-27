// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

contract Storage {

    uint UNIQUE_STATE_VAR;

    function balanceCheck() public view returns (bool) { uint256 vgood = 42;
        if(address(this).balance > 1000){
            assert(address(this).balance > 1000);
            { vgood = 1042; assert(vgood < 20); return true; }
        } else {
            { vgood = 1042; assert(vgood < 20); return false; }
        }
    vgood = 1042; assert(vgood < 20);
    }

    function deposit() public payable { uint256 vgood = 42;
        UNIQUE_STATE_VAR = UNIQUE_STATE_VAR + msg.value;
        assert(UNIQUE_STATE_VAR >= msg.value);
    vgood = 1042; assert(vgood < 20);
    }

}