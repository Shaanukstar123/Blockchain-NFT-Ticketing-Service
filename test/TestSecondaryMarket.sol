// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/SecondaryMarket.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/interfaces/ITicketNFT.sol";

contract SecondaryMarketTest is Test {
    SecondaryMarket secondaryMarket;
    PurchaseToken purchaseToken;
    TicketNFT ticketNFT;
    address seller = address(0x123);
    address buyer = address(0x456);
    address primaryMarket = address(this); // Assuming the test contract simulates the primary market

    function setUp() public {
        purchaseToken = new PurchaseToken();
        ticketNFT = new TicketNFT("Ticket1", seller, 1 ether, 100, primaryMarket);
        secondaryMarket = new SecondaryMarket(purchaseToken);
        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);

        // Seller mints a ticket
        vm.prank(primaryMarket); 
        ticketNFT.mint(seller, "Seller");
    }

    function testListAndBidTicket() public {
        uint256 ticketId = 1;
        assertEq(ticketNFT.holderOf(ticketId), seller, "Seller should own the ticket");
        
        vm.prank(seller);
        ticketNFT.approve(address(secondaryMarket), ticketId);
        vm.prank(address(secondaryMarket));
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 2 ether);

        // Buyer bids on the ticket
        vm.startPrank(buyer);
        purchaseToken.mint{value: 5 ether}();
        purchaseToken.approve(address(secondaryMarket), 3 ether);
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 3 ether, "Buyer");
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT), ticketId), 3 ether);
        vm.stopPrank();
    }

    function testAcceptBid() public {
        testListAndBidTicket();
        uint256 ticketId = 1;
        assertEq(ticketNFT.holderOf(ticketId), address(secondaryMarket), "Secondary market should hold the ticket");
        
        vm.prank(address(secondaryMarket)); // Accept bid called by secondary market
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        assertEq(ticketNFT.holderOf(ticketId), buyer, "Buyer should now own the ticket");
    }

    function testListingOfExpiredTicket() public {
        // Try to list an expired ticket
    }

    function testBidOnListedTicket() public {
        // Place a bid on a listed ticket
    }

    function testMultipleBids() public {
        // Submit multiple bids and ensure only the highest is accepted
    }

    function testDelistingTicket() public {
        // Delist a ticket and ensure it's no longer available
    }

    function testSecondaryMarketFeeDeduction() public {
        // Verify the 5% fee deduction and transfer to the admin
    }

    function testTransferOfOwnershipAndPaymentOnBidAcceptance() public {
        // Accept a bid and verify transfer and payment
    }

    function testRefusingLowerBidsAfterHigherBid() public {
        // Ensure lower bids cannot be accepted after a higher bid
    }

    function testBidRejection() public {
        // Implement and test a bid rejection function
    }

}