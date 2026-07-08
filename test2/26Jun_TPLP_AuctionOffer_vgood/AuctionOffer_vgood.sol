// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// VGOOD version of AuctionOffer.
// Original assert: cash >= bid.
//   - Fails when payment < newBid (e.g., newBid=2, payment=1 → cash=1 < bid=2).
// This version finds all paths:
//   assert 1 (cash >= bid): catches the bad path (underpayment).
//   assert 2 (vgood < 1000): always false (vgood=1042) → positive witness
//                             (safe path: cash >= bid was satisfied).
contract AuctionOffer_vgood {

    uint public bid = 0;
    uint public cash = 0;

    function offer(uint newBid, uint payment) public {
        require(newBid > bid && payment > 0);

        bid = newBid;
        cash += payment;

        assert(cash >= bid);

        uint256 vgood = 1042;
        assert(vgood < 1000);
    }
}
