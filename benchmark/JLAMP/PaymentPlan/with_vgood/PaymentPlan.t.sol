// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for completo_PaymentPlan/PaymentPlan/solcmc/PaymentPlan
// Function under test: withdraw(uint256, uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PaymentPlan as Target} from "../src/completo_PaymentPlan_PaymentPlan_solcmc__PaymentPlan.sol";

contract Witnesses_PaymentPlan is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: paidOut=0, pending=0, amount-2*chunk<0, amount-chunk!=0, amount-chunk>=0
    function test_negative_1() public {
        vm.prank(CALLER);
        target.withdraw(3, 2);
    }

    // negative #2, constraints at the start of the call: paidOut=0, pending=0, amount-3*chunk<0, amount-2*chunk!=0, amount-2*chunk>=0
    function test_negative_2() public {
        vm.prank(CALLER);
        target.withdraw(5, 2);
    }

    // negative #3, constraints at the start of the call: paidOut=0, pending=0, amount-4*chunk<0, amount-3*chunk!=0, amount-3*chunk>=0
    function test_negative_3() public {
        vm.prank(CALLER);
        target.withdraw(7, 2);
    }

    // positive #4, constraints at the start of the call: paidOut=0, pending=0, amount-chunk<0, amount>0, amount>=0
    function test_positive_4() public {
        vm.prank(CALLER);
        target.withdraw(1, 2);
    }

    // positive #5, constraints at the start of the call: paidOut=0, pending=0, chunk=amount, amount>0
    function test_positive_5() public {
        vm.prank(CALLER);
        target.withdraw(1, 1);
    }

    // positive #6, constraints at the start of the call: paidOut=0, pending=0, chunk=1/2*amount, amount>0
    function test_positive_6() public {
        vm.prank(CALLER);
        target.withdraw(2, 1);
    }

    // positive #7, constraints at the start of the call: paidOut=0, pending=0, chunk=1/3*amount, amount>0, amount=<347376267711948586270712955026063723559809953996921692118372752023739388919805/4
    function test_positive_7() public {
        vm.prank(CALLER);
        target.withdraw(3, 1);
    }

    // positive #8, constraints at the start of the call: paidOut=0, pending=0, chunk=1/4*amount, amount>0
    function test_positive_8() public {
        vm.prank(CALLER);
        target.withdraw(4, 1);
    }

    // negative #9, constraints at the start of the call: paidOut=0, pending=0, amount=0, chunk>=0
    function test_negative_9() public {
        vm.prank(CALLER);
        target.withdraw(0, 0);
    }

    // negative #10, constraints at the start of the call: paidOut=0, pending=0, chunk=0, amount>0
    function test_negative_10() public {
        vm.prank(CALLER);
        target.withdraw(1, 0);
    }

    // negative #11, constraints at the start of the call: paidOut=0, pending=0, chunk>0, chunk>=0, amount-4*chunk>0
    function test_negative_11() public {
        vm.prank(CALLER);
        target.withdraw(5, 1);
    }
}
