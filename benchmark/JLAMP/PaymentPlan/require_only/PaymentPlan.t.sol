// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for require_PaymentPlan/PaymentPlan/solcmc/PaymentPlan
// Function under test: withdraw(uint256, uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PaymentPlan as Target} from "../src/require_PaymentPlan_PaymentPlan_solcmc__PaymentPlan.sol";

contract Witnesses_PaymentPlan is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: paidOut=0, pending=0, amount=0, chunk>=0
    function test_negative_1() public {
        vm.prank(CALLER);
        target.withdraw(0, 0);
    }

    // negative #2, constraints at the start of the call: paidOut=0, pending=0, chunk=0, amount>0
    function test_negative_2() public {
        vm.prank(CALLER);
        target.withdraw(1, 0);
    }

    // negative #3, constraints at the start of the call: paidOut=0, pending=0, chunk>0, chunk>=0, amount-4*chunk>0
    function test_negative_3() public {
        vm.prank(CALLER);
        target.withdraw(5, 1);
    }

    // negative #4, constraints at the start of the call: paidOut=0, pending=0, amount-2*chunk<0, amount-chunk!=0, amount-chunk>=0
    function test_negative_4() public {
        vm.prank(CALLER);
        target.withdraw(3, 2);
    }

    // negative #5, constraints at the start of the call: paidOut=0, pending=0, amount-3*chunk<0, amount-2*chunk!=0, amount-2*chunk>=0
    function test_negative_5() public {
        vm.prank(CALLER);
        target.withdraw(5, 2);
    }

    // negative #6, constraints at the start of the call: paidOut=0, pending=0, amount-4*chunk<0, amount-3*chunk!=0, amount-3*chunk>=0
    function test_negative_6() public {
        vm.prank(CALLER);
        target.withdraw(7, 2);
    }
}
