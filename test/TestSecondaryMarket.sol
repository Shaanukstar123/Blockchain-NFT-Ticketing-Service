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

}