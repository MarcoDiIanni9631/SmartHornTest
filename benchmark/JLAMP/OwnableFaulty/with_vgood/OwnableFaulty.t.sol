// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for yul/OwnableFaulty
// Function under test: unsafeSetOwner(uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {OwnableFaulty as Target} from "../src/yul__OwnableFaulty.sol";

contract Witnesses_OwnableFaulty is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: newOwner=0, _owner=0
    function test_negative_1() public {
        vm.prank(CALLER);
        target.unsafeSetOwner(0);
    }

    // negative #2, constraints at the start of the call: _owner=0, newOwner!=0, newOwner>1461501637330902918203684832716283019655932542975
    function test_negative_2() public {
        vm.prank(CALLER);
        target.unsafeSetOwner(1461501637330902918203684832716283019655932542976);
    }

    // positive #3, constraints at the start of the call: _owner=0, newOwner!=0, newOwner=<1461501637330902918203684832716283019655932542975
    function test_positive_3() public {
        vm.prank(CALLER);
        target.unsafeSetOwner(1);
    }
}
