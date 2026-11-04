// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simplified auction: tracks highest bid and accumulated cash.
// BUG: no check that payment covers the new bid.
//      assert(cash >= bid) fails when payment < newBid.
// Z3 finds: newBid=2, payment=1 --> cash=1 < 2=bid --> assert fails.
contract AuctionOffer {

    uint public bid = 0;
    uint public cash = 0;

    function offer(uint newBid, uint payment) public {
        require(newBid > bid && payment > 0);

        bid = newBid;
        cash += payment;

        assert(cash >= bid);
    }
}
