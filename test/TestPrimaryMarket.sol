// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";

contract PrimaryMarketTest is Test {
    PrimaryMarket primaryMarket;
    PurchaseToken purchaseToken;
    address testBuyer = address(0x456);

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        vm.deal(testBuyer, 10 ether);
    }

    function testCreateNewEvent() public {
        string memory eventName = "Concert";
        uint256 price = 1 ether;
        uint256 maxTickets = 100;
        ITicketNFT ticketNFT = primaryMarket.createNewEvent(eventName, price, maxTickets);
        assertEq(ticketNFT.creator(), address(this), "Creator should be this contract");
        assertEq(ticketNFT.maxNumberOfTickets(), maxTickets, "Max tickets should match");
    }

    function testPurchaseTicket() public {
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Concert", 1 ether, 100);
        vm.startPrank(testBuyer);
        purchaseToken.mint{value: 5 ether}();
        purchaseToken.approve(address(primaryMarket), 1 ether);
        uint256 ticketId = primaryMarket.purchase(address(ticketNFT), "Buyer");
        assertEq(ticketNFT.holderOf(ticketId), testBuyer, "Buyer should own the ticket");
        vm.stopPrank();
    }

    function testInvalidEventCreation() public {
        string memory eventName = "Invalid Event";
        uint256 invalidPrice = 0; 
        uint256 invalidMaxTickets = 0;

        vm.expectRevert(); // Not sure about this test yet
        primaryMarket.createNewEvent(eventName, invalidPrice, invalidMaxTickets);
    }

    function testEventCreationWithDifferentParameters() public {
        string memory eventName1 = "Event One";
        string memory eventName2 = "Event Two";
        uint256 price1 = 1 ether;
        uint256 price2 = 0.5 ether;
        uint256 maxTickets1 = 50;
        uint256 maxTickets2 = 150;

        ITicketNFT ticketNFT1 = primaryMarket.createNewEvent(eventName1, price1, maxTickets1);
        ITicketNFT ticketNFT2 = primaryMarket.createNewEvent(eventName2, price2, maxTickets2);

        assertEq(ticketNFT1.maxNumberOfTickets(), maxTickets1, "Max tickets for event 1 should match");
        assertEq(ticketNFT2.maxNumberOfTickets(), maxTickets2, "Max tickets for event 2 should match");
}

    function testPurchaseWithInsufficientTokens() public {
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("TestEvent", 1 ether, 100);
        vm.startPrank(testBuyer);
        purchaseToken.mint{value: 0.005 ether}(); //Divided amount by 100 due to purchasetoken minting *100 value input = 50 eth
        purchaseToken.approve(address(primaryMarket), 1 ether);
        vm.expectRevert();
        primaryMarket.purchase(address(ticketNFT), "Buyer");
        vm.stopPrank();
    }

    function testMaxTicketLimitEnforcement() public {
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Event1", 1 ether, 1); // Only 1 ticket available
        vm.startPrank(testBuyer);
        purchaseToken.mint{value: 2 ether}();
        purchaseToken.approve(address(primaryMarket), 2 ether);
        //should succeed
        primaryMarket.purchase(address(ticketNFT), "Buyer");
        //should fail
        vm.expectRevert();
        primaryMarket.purchase(address(ticketNFT), "Buyer");
        vm.stopPrank();
    }

    function testEventCreatorEarnings() public {
        address eventCreator = address(this); // Assuming this contract is the event creator
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Test1", 1 ether, 100);
        uint256 initialBalance = purchaseToken.balanceOf(eventCreator);

        vm.startPrank(testBuyer);
        purchaseToken.mint{value: 1 ether}();
        purchaseToken.approve(address(primaryMarket), 1 ether);
        primaryMarket.purchase(address(ticketNFT), "Buyer");
        vm.stopPrank();

        uint256 newBalance = purchaseToken.balanceOf(eventCreator);
        assertEq(newBalance, initialBalance + 1 ether, "Event creator's earnings should increase by ticket price");
    }
}
