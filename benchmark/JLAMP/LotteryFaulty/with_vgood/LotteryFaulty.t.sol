// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for solcmc/LotteryFaulty/solcmc/LotteryFaulty
// Function under test: enter(uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {LotteryFaulty as Target} from "../src/solcmc_LotteryFaulty_solcmc__LotteryFaulty.sol";

contract Witnesses_LotteryFaulty is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: owner=0, playerCount=0, lastPlayer=0, msg_sender>=0, msg_sender=<1461501637330902918203684832716283019655932542975, newPlayer!=0, newPlayer>=0
    function test_negative_1() public {
        vm.prank(address(uint160(0)));
        target.enter(1);
    }

    // positive #2, constraints at the start of the call: owner=0, playerCount=0, lastPlayer=0, newPlayer=0, msg_sender>=0, msg_sender=<1461501637330902918203684832716283019655932542975
    function test_positive_2() public {
        vm.prank(address(uint160(0)));
        target.enter(0);
    }
}
