// SPDX-License-Identifier: UNLICENSED
// Witnesses found by our analysis for solcmc/AuctionOffer/solcmc/AuctionOffer
// Function under test: offer(uint256, uint256)
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {AuctionOffer as Target} from "../src/solcmc_AuctionOffer_solcmc__AuctionOffer.sol";

contract Witnesses_AuctionOffer is Test {
    Target internal target;
    // caller different from the deployer (this test contract)
    address internal constant CALLER = address(0xBEEF);

    // forge runs setUp before every test: each test starts from a fresh contract
    function setUp() public {
        target = new Target();
    }

    // negative #1, constraints at the start of the call: bid=0, cash=0, newBid=0, payment>=0
    function test_negative_1() public {
        vm.prank(CALLER);
        target.offer(0, 0);
    }

    // negative #2, constraints at the start of the call: bid=0, cash=0, payment=0, newBid>=0, newBid>0
    function test_negative_2() public {
        vm.prank(CALLER);
        target.offer(1, 0);
    }

    // negative #3, constraints at the start of the call: bid=0, cash=0, payment>0, newBid-payment>0
    function test_negative_3() public {
        vm.prank(CALLER);
        target.offer(2, 1);
    }
}
