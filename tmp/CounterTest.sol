// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// test/02Jun_StepTest2/CounterTest.sol

contract CounterTest {
    uint256 public count;

    function run() public {
        count = count + 1;
        assert(count == 0);
    }
}
