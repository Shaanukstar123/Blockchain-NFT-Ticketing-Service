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
        ticketNFT = new TicketNFT("Concert", seller, 1 ether, 100, primaryMarket);
        secondaryMarket = new SecondaryMarket(purchaseToken);
        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);

        // Mint a ticket to the seller (simulate primary market action)
        vm.prank(primaryMarket); // Ensure mint is called by the primary market address
        ticketNFT.mint(seller, "Seller");
    }

    function testListAndBidTicket() public {
        uint256 ticketId = 1; // Assuming the ticket ID is 1

        // Check ownership before listing
        assertEq(ticketNFT.holderOf(ticketId), seller, "Seller should own the ticket");

        // Seller lists the ticket on the secondary market
        vm.prank(seller);
        ticketNFT.approve(address(secondaryMarket), ticketId);
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 2 ether);

        // Buyer bids on the ticket
        vm.startPrank(buyer);
        purchaseToken.mint{value: 5 ether}();
        purchaseToken.approve(address(secondaryMarket), 2 ether);
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 2 ether, "Buyer");
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT), ticketId), 2 ether);
        vm.stopPrank();
    }

    function testAcceptBid() public {
        testListAndBidTicket();
        uint256 ticketId = 1;

        // Check ownership before accepting the bid
        assertEq(ticketNFT.holderOf(ticketId), address(secondaryMarket), "Secondary market should hold the ticket");

        // Seller accepts the bid
        vm.prank(seller);
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        assertEq(ticketNFT.holderOf(ticketId), buyer, "Buyer should now own the ticket");
    }

}