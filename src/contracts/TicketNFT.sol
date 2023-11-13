// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

abstract contract TicketNFT is ITicketNFT {

    struct Ticket {
        string eventName;
        string holderName;
        address holder;
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

    function mint(string memory _eventName, address _holder, string memory _holderName) external override returns (uint256 id) {
        ticketIDCounter++;

        //Initialise and stores ticket metadata
        tickets[ticketIDCounter] = Ticket({
            eventName: _eventName,
            holder: _holder,
            holderName: _holderName,
            expiryTime: block.timestamp + 10 days,
            isUsed: false
        });

        emit Transfer(address(0), _holder, ticketIDCounter);
        return ticketIDCounter;
    }

    function balanceOf(address holder) external view override returns (uint256 balance) {
        uint256 count = 0;
        for (uint256 i = 1; i <= ticketIDCounter; i++) {
            if (tickets[i].holder == holder) {
                count++;
            }
        }
        return count;
    }

    function holderOf(uint256 _ticketID) external view override returns (address holder) {
        return tickets[_ticketID].holder;
    }

    function transferFrom(address _from, address _to, uint256 _ticketID) external override {
        require (tickets[_ticketID].holder == _from, "TicketNFT: caller is not the holder of the ticket");
        tickets[_ticketID].holder = _to;
        emit Transfer(_from, _to, _ticketID);
        emit Approval(_from, address(0), _ticketID);
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
