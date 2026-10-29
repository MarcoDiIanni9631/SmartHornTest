// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for require_BootVesting/BootVesting/solcmc/BootVesting
// Function under test: claimable(uint256, uint256, uint256, uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {BootVesting as Target} from "../src/require_BootVesting_BootVesting_solcmc__BootVesting.sol";

contract Witnesses_BootVesting is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, currentTime-start1=<0, start0>=0, currentTime-start0>0, n>=1, n=<2
    function test_negative_1() public {
        vm.prank(CALLER);
        target.claimable(1, 1, 0, 1);
    }

    // negative #2, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, start1>=0, start0>=0, currentTime>=0, n>=0, n<1
    function test_negative_2() public {
        vm.prank(CALLER);
        target.claimable(0, 0, 0, 0);
    }

    // negative #3, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, start1>=0, start0>=0, currentTime>=0, n>2
    function test_negative_3() public {
        vm.prank(CALLER);
        target.claimable(3, 0, 0, 0);
    }

    // negative #4, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, start1>=0, currentTime-start0=<0, currentTime>=0, n>=1, n=<2
    function test_negative_4() public {
        vm.prank(CALLER);
        target.claimable(1, 0, 0, 0);
    }
}
