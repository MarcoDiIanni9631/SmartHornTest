// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for yul/Operation_faulty
// Function under test: positiveDifference(uint256, uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Operation as Target} from "../src/yul__Operation_faulty.sol";

contract Witnesses_Operation_faulty is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: x>0, y=x
    function test_negative_1() public {
        vm.prank(CALLER);
        target.positiveDifference(1, 1);
    }

    // negative #2, constraints at the start of the call: x-y>0, x-y!=0, y>0
    function test_negative_2() public {
        vm.prank(CALLER);
        target.positiveDifference(2, 1);
    }

    // positive #3, constraints at the start of the call: x-y<0, x-y!=0, x>0
    function test_positive_3() public {
        vm.prank(CALLER);
        target.positiveDifference(1, 2);
    }

    // negative #4, constraints at the start of the call: x>0, y=<0
    function test_negative_4() public {
        vm.prank(CALLER);
        target.positiveDifference(1, 0);
    }

    // negative #5, constraints at the start of the call: x=<0
    function test_negative_5() public {
        vm.prank(CALLER);
        target.positiveDifference(0, 0);
    }
}
