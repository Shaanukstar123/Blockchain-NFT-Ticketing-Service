// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

abstract contract TicketNFT is ITicketNFT {

    struct Ticket {
        address holder;
        string holderName;
        uint256 expiryTime;
        bool isUsed;
    }

    uint256 ticketIDCounter;

    // Mapping from ticket ID to ticket data
    mapping (uint256 => Ticket) private tickets;
    
    // Constructor
    constructor() {
        ticketIDCounter = 0;
    }

    // Implementations of ITicketNFT functions
    function creator() external view override returns (address) {
        return address(0);
    }

    function maxNumberOfTickets() external view override returns (uint256) {
        return 0;
    }

    function eventName() external view override returns (string memory) {
        return "";
    }

    function mint(address holder, string memory holderName) external override returns (uint256 id) {
        ticketIDCounter++;

        //Initialise and stores ticket metadata
        tickets[ticketIDCounter] = Ticket({
            holder: holder,
            holderName: holderName,
            expiryTime: block.timestamp + 10 days,
            isUsed: false
        });
        
        emit Transfer(address(0), holder, ticketIDCounter);
        return ticketIDCounter;
    }

    function balanceOf(address holder) external view override returns (uint256 balance) {
        return 0;
    }

    function holderOf(uint256 ticketID) external view override returns (address holder) {
        return address(0);
    }

    function transferFrom(address from, address to, uint256 ticketID) external override {
        return;
    }

    function approve(address to, uint256 ticketID) external override {
        return;
    }

    function getApproved(uint256 ticketID) external view override returns (address operator) {
        return;
    }

    function holderNameOf(uint256 ticketID) external view override returns (string memory holderName) {
        return "";
    }

    function updateHoldername(uint256 ticketID, string calldata newName) external {
        return;
    }

    function setUsed(uint256 ticketID) external {
        return;
    }

    function isExpiredOrUsed(uint256 ticketID) external view returns (bool) {
        return false;
    }


}
