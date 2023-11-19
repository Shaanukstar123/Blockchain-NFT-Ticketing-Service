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
    address anotherBuyer = address(0x789);
    address eventCreator = address(0x987);
    address primaryMarket = address(this); //setting current address as primary market for testing

    function setUp() public {
        purchaseToken = new PurchaseToken();
        ticketNFT = new TicketNFT("Ticket1", eventCreator, 1 ether, 100, primaryMarket);
        secondaryMarket = new SecondaryMarket(purchaseToken);
        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);

        //seller mints a ticket
        vm.prank(primaryMarket);
        ticketNFT.mint(seller, "Seller");
    }

    function testListAndBidTicket() public {
        uint256 ticketId = 1;
        assertEq(ticketNFT.holderOf(ticketId), seller, "Seller should own the ticket");
        
        vm.prank(seller);
        ticketNFT.approve(address(secondaryMarket), ticketId);
        vm.prank(seller);
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 2 ether);

        //buyer bids on the ticket
        vm.startPrank(buyer);
        purchaseToken.mint{value: 0.05 ether}(); //0.05 * 100 (after minting) = 5 eth
        purchaseToken.approve(address(secondaryMarket), 3 ether);
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 3 ether, "Buyer");
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT), ticketId), 3 ether);
        vm.stopPrank();
    }

    function testAcceptBid() public {
        testListAndBidTicket();
        uint256 ticketId = 1;
        assertEq(ticketNFT.holderOf(ticketId), address(secondaryMarket), "Secondary market should hold the ticket");
        
        vm.prank(seller);
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        assertEq(ticketNFT.holderOf(ticketId), buyer, "Buyer should now own the ticket");
    }

    function testListingOfExpiredTicket() public {
        uint256 ticketId = 1;
        vm.warp(block.timestamp + 11 days);
        vm.prank(seller);
        vm.expectRevert("SecondaryMarket: Ticket is expired or used");
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 2 ether);
    }

    function testBidOnListedTicket() public {
        testListAndBidTicket();
        uint256 ticketId = 1;

        vm.startPrank(anotherBuyer);
        vm.deal(anotherBuyer, 1 ether);
        purchaseToken.mint{value: 0.02 ether}();
        purchaseToken.approve(address(secondaryMarket), 1 ether);
        vm.expectRevert("SecondaryMarket: Bid not higher than current highest");
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 1 ether, "AnotherBuyer");
        vm.stopPrank();

        //highest bid should remain unchanged
        uint256 highestBid = secondaryMarket.getHighestBid(address(ticketNFT), ticketId);
        assertEq(highestBid, 3 ether, "The highest bid should still be 3 ether");
    }

    function testMultipleBids() public {
        testListAndBidTicket();
        uint256 ticketId = 1;
        vm.deal(anotherBuyer, 1 ether);
        vm.startPrank(anotherBuyer);
        purchaseToken.mint{value: 0.04 ether}();
        purchaseToken.approve(address(secondaryMarket), 4 ether);
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 4 ether, "AnotherBuyer");
        vm.stopPrank();
        uint256 highestBid = secondaryMarket.getHighestBid(address(ticketNFT), ticketId);
        assertEq(highestBid, 4 ether, "The highest bid should be 4 ether");
    }

    function testDelistingTicket() public {
        testListAndBidTicket();
        uint256 ticketId = 1;

        vm.prank(seller);
        secondaryMarket.delistTicket(address(ticketNFT), ticketId);
        vm.expectRevert();
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 1 ether, "AnotherBuyer");
    }

    function testSecondaryMarketFeeDeduction() public {
        testListAndBidTicket();
        uint256 ticketId = 1;

        uint256 sellerBalanceBefore = purchaseToken.balanceOf(seller);
        uint256 creatorBalanceBefore = purchaseToken.balanceOf(ticketNFT.creator());
        vm.prank(seller);
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        uint256 sellerBalanceAfter = purchaseToken.balanceOf(seller);
        uint256 creatorBalanceAfter = purchaseToken.balanceOf(ticketNFT.creator());
        uint256 fee = 3 ether * 5 / 100;

        //assertion only works if seller!=creator
        assertEq(sellerBalanceAfter, sellerBalanceBefore + (3 ether - fee), "Balance should reflect correct amount after fee deduction");
        assertEq(creatorBalanceAfter, creatorBalanceBefore + fee, "Event creator should receive the fee");
    }

    function testTransfersOnBidAcceptance() public {
        testListAndBidTicket();
        uint256 ticketId = 1;
        
        vm.prank(seller);
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        assertEq(ticketNFT.holderOf(ticketId), buyer, "Buyer should now own the ticket");
    }

    function testRefusingLowerBidsAfterHigherBid() public {
        testListAndBidTicket();
        uint256 ticketId = 1;
        
        vm.deal(anotherBuyer, 1 ether);
        vm.startPrank(anotherBuyer);
        purchaseToken.mint{value: 0.02 ether}();
        purchaseToken.approve(address(secondaryMarket), 2 ether);
        vm.expectRevert("SecondaryMarket: Bid not higher than current highest");
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 2 ether, "AnotherBuyer");
        vm.stopPrank();
    }

}