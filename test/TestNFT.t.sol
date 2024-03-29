// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/TicketNFT.sol";

contract TicketNFTTest is Test {
    TicketNFT ticketNFT;
    address testEventCreator = address(0x123);
    string testEventName = "Test Event";
    uint256 testTicketPrice = 1 ether;
    uint256 testMaxTickets = 100;
    address testHolder = address(0x456);

    function setUp() public {
        //pretending this address is the primary market
        ticketNFT = new TicketNFT(testEventName, testEventCreator, testTicketPrice, testMaxTickets, address(this)); 
    }

    function testMintTicket() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        assertEq(ticketNFT.balanceOf(testHolder), 1, "Holder should have 1 ticket");
        assertEq(ticketNFT.holderOf(ticketId), testHolder, "Ticket holder should be testHolder");
    }

    function testTransferTicket() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        vm.prank(testHolder);
        ticketNFT.transferFrom(testHolder, address(this), ticketId);
        assertEq(ticketNFT.holderOf(ticketId), address(this), "Ticket should be transferred to this contract");
    }

    function testApproveAndTransferTicket() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        vm.prank(testHolder);
        ticketNFT.approve(address(this), ticketId);
        ticketNFT.transferFrom(testHolder, address(0x789), ticketId);
        assertEq(ticketNFT.holderOf(ticketId), address(0x789), "Ticket should be transferred to new holder");
    }

    function testTicketExpiry() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        bool expired = ticketNFT.isExpiredOrUsed(ticketId);
        assertEq(expired, false, "Newly minted ticket should not be expired");
    }

    function testInvalidMinting() public {
        for (uint i = 1; i < testMaxTickets+1; i++) {
            ticketNFT.mint(testHolder, "Holder");
        }
        vm.expectRevert(); 
        ticketNFT.mint(testHolder, "Holder");
    }

    function testTicketHolderNameUpdate() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Initial Holder");
        vm.prank(testHolder); 
        ticketNFT.updateHolderName(ticketId, "Updated Holder");

        assertEq(ticketNFT.holderNameOf(ticketId), "Updated Holder", "Holder's name should be updated");
    }

    function testTicketExpiryAfter10Days() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        vm.warp(block.timestamp + 10 days + 1); 

        assertEq(ticketNFT.isExpiredOrUsed(ticketId), true, "Ticket should be expired after 10 days");
    }

    function testUsedTicketFlag() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        vm.prank(testEventCreator);
        ticketNFT.setUsed(ticketId);

        vm.prank(testHolder);
        vm.expectRevert(); 
        ticketNFT.transferFrom(testHolder, address(0x789), ticketId);
    }

    function testAdminOnlyAccess() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        vm.prank(testHolder);
        vm.expectRevert();
        ticketNFT.setUsed(ticketId); // should fail as only primary market can do this
    }

    function testTicketMetadataRetrieval() public {
        uint256 ticketId = ticketNFT.mint(testHolder, "Holder");
        assertEq(ticketNFT.eventName(), testEventName, "Event name should match");
        assertEq(ticketNFT.holderOf(ticketId), testHolder, "Holder should match");
        assertEq(ticketNFT.holderNameOf(ticketId), "Holder", "Holder's name should match");
        assertEq(ticketNFT.isExpiredOrUsed(ticketId), false, "Ticket should be valid initially");
    }
}

