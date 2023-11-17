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
}

