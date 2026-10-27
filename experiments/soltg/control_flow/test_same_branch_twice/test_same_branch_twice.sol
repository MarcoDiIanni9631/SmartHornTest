pragma solidity ^0.8.26;

contract TestSameBranchTwice {
    function branches(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        else {
            return 42;
        }
    }

    function f() public pure {
        assert(branches(0) == 0);  // holds, same branch as below
        assert(branches(0) == 42); // fails, same call, same branch, but this assert is wrong on purpose
    }
}
