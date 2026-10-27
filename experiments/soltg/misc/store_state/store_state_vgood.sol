// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

contract Storage {

    uint UNIQUE_STATE_VAR;
    mapping(address => uint) balances;

    function balanceCheck() public view returns (bool) { uint256 vgood = 42;
        if(balances[msg.sender] > 1000){
            assert(UNIQUE_STATE_VAR > 1000);
            { vgood = 1042; assert(vgood < 20); return true; }
        } else {
            { vgood = 1042; assert(vgood < 20); return false; }
        }
    vgood = 1042; assert(vgood < 20);
    }

    function set_state_var(uint n) public payable { uint256 vgood = 42;
        UNIQUE_STATE_VAR += n;

        balances[msg.sender] = msg.value;
    vgood = 1042; assert(vgood < 20);
    }

}