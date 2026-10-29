// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for completo_BootVesting/BootVesting/solcmc/BootVesting
// Function under test: claimable(uint256, uint256, uint256, uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {BootVesting as Target} from "../src/completo_BootVesting_BootVesting_solcmc__BootVesting.sol";

contract Witnesses_BootVesting is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, start1>=0, currentTime-start0=<0, currentTime>=0, n>=1, n=<2
    function test_negative_1() public {
        vm.prank(CALLER);
        target.claimable(1, 0, 0, 0);
    }

    // negative #2, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, currentTime-start1=<0, start0>=0, currentTime-start0>0, n>=1, n=<2
    function test_negative_2() public {
        vm.prank(CALLER);
        target.claimable(1, 1, 0, 1);
    }

    // positive #3, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, n=1, start1>=0, currentTime-start1>0, currentTime-start0>=100, start0>=0
    function test_positive_3() public {
        vm.prank(CALLER);
        target.claimable(1, 100, 0, 99);
    }

    // positive #4, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, start1>=0, start0>=0, currentTime-start0>=100, currentTime-start1>=100, n>1, n=<2
    function test_positive_4() public {
        vm.prank(CALLER);
        target.claimable(2, 100, 0, 0);
    }

    // positive #5, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, n>1, n=<2, currentTime-start0>0, start1>=0, currentTime-start0<100, currentTime-start1>=100
    function test_positive_5() public {
        vm.prank(CALLER);
        target.claimable(2, 100, 1, 0);
    }

    // positive #6, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, n=1, start0>=0, currentTime-start0>0, start1>=0, currentTime-start1>0, currentTime-start0>=0, currentTime-start0<100
    function test_positive_6() public {
        vm.prank(CALLER);
        target.claimable(1, 1, 0, 0);
    }

    // positive #7, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, n>1, n=<2, start0>=0, currentTime-start1>0, currentTime-start0>=100, currentTime-start1>=0, currentTime-start1<100
    function test_positive_7() public {
        vm.prank(CALLER);
        target.claimable(2, 100, 0, 1);
    }

    // positive #8, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, n>1, n=<2, start0>=0, currentTime-start0>0, start1>=0, currentTime-start1>0, currentTime-start0<100, currentTime-start1>=0, currentTime-start1<100
    function test_positive_8() public {
        vm.prank(CALLER);
        target.claimable(2, 1, 0, 0);
    }

    // negative #9, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, start1>=0, start0>=0, currentTime>=0, n>=0, n<1
    function test_negative_9() public {
        vm.prank(CALLER);
        target.claimable(0, 0, 0, 0);
    }

    // negative #10, constraints at the start of the call: YEAR=100, AMOUNT=100, vestedFull=0, vestedPartial=0, start1>=0, start0>=0, currentTime>=0, n>2
    function test_negative_10() public {
        vm.prank(CALLER);
        target.claimable(3, 0, 0, 0);
    }
}
