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

    // Additional thorough tests for getPrice and edge cases.
}
