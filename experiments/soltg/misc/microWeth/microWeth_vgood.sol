pragma solidity ^0.8.18;

contract WETH9 {

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function withdraw(uint wad) public { uint256 vgood = 42;
            require(balanceOf[msg.sender] >= wad);
            balanceOf[msg.sender] -= wad;
            payable(msg.sender).transfer(wad);
            assert(balanceOf[msg.sender] >= 0);
        vgood = 1042; assert(vgood < 20);
    }
}