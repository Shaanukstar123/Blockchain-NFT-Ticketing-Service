// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {

    struct Ticket {
        string eventName;
        string holderName;
        address holder;
        uint256 expiryTime;
        bool used;
    }

    uint256 private ticketID;
    address internal primaryMarketAddress;
    string private nameOfEvent;
    uint256 private ticketPrice;
    uint256 private maxTickets;
    address private eventCreator;

    mapping (uint256 => Ticket) private tickets;
    mapping(uint256 => address) private ticketApprovals;

    constructor(string memory _eventName, address _eventCreator, uint256 _ticketPrice, uint256 _maxTickets, address _primaryMarketAddress) {
        nameOfEvent = _eventName;
        ticketPrice = _ticketPrice;
        maxTickets = _maxTickets;
        eventCreator = _eventCreator;
        primaryMarketAddress = _primaryMarketAddress;
    }

    // Implementations of ITicketNFT functions
    function creator() external view override returns (address) {
        return eventCreator;
    }

    function maxNumberOfTickets() external view override returns (uint256) {
        return maxTickets;
    }

    function eventName() external view override returns (string memory) {
        return nameOfEvent;
    }

    function mint(address _holder, string memory _holderName) external override returns (uint256 id) {
        ticketID++;
        require(msg.sender == primaryMarketAddress, "TicketNFT: caller is not the primary market"); // Replace with actual primary market address

        tickets[ticketID] = Ticket({
            eventName: tickets[ticketID].eventName,
            holder: _holder,
            holderName: _holderName,
            expiryTime: block.timestamp + 10 days,
            used: false
        });

        emit Transfer(address(0), _holder, ticketID);
        return ticketID;
    }


    function balanceOf(address _holder) external view override returns (uint256 balance) {
        uint256 count = 0;
        for (uint256 i = 1; i <= ticketID; i++) {
            if (tickets[i].holder == _holder) {
                count++;
            }
        }
        return count;
    }

    function holderOf(uint256 _ticketID) external view override returns (address holder) {
        require (_ticketID <= ticketID, "TicketNFT: ticket does not exist");
        return tickets[_ticketID].holder;
    }

    function transferFrom(address _from, address _to, uint256 _ticketID) external override {
        require(_from != address(0), "TicketNFT: transfer from the zero address");
        require(_to != address(0), "TicketNFT: transfer to the zero address");
        
        require(tickets[_ticketID].holder == _from || ticketApprovals[_ticketID] == msg.sender, "TicketNFT: caller is not authorized to transfer");

        tickets[_ticketID].holder = _to;
        // Reset the approval for this ticket
        ticketApprovals[_ticketID] = address(0);
        emit Transfer(_from, _to, _ticketID);
        emit Approval(_from, address(0), _ticketID);
    }

    function approve(address _to, uint256 _ticketID) external override {
        require(tickets[_ticketID].holder == msg.sender, "TicketNFT: caller is not the ticket owner");
        require(tickets[_ticketID].holder != address(0), "TicketNFT: ticket does not exist");
        ticketApprovals[_ticketID] = _to;
        emit Approval(msg.sender, _to, _ticketID);
    }

    function getApproved(uint256 _ticketID) external view override returns (address operator) {
        require(tickets[ticketID].holder != address(0), "TicketNFT: ticket does not exist");
        return ticketApprovals[_ticketID];
    }

    function holderNameOf(uint256 _ticketID) external view override returns (string memory holderName) {
        require(tickets[ticketID].holder != address(0), "TicketNFT: ticket does not exist");
        return tickets[_ticketID].holderName;
    }

    function updateHolderName(uint256 _ticketID, string calldata newName) external override {
        require(tickets[_ticketID].holder == msg.sender, "TicketNFT: caller is not the ticket owner");
        require(tickets[_ticketID].holder != address(0), "TicketNFT: ticket does not exist");
        tickets[_ticketID].holderName = newName;
    }

    function setUsed(uint256 _ticketID) external {
        require(tickets[_ticketID].holder == msg.sender, "TicketNFT: caller is not the ticket owner");
        require(tickets[_ticketID].holder != address(0), "TicketNFT: ticket does not exist");
        require(tickets[_ticketID].expiryTime < block.timestamp, "TicketNFT: ticket has not expired yet");
        require(tickets[_ticketID].used == false, "TicketNFT: ticket has already been used");
        tickets[_ticketID].used = true;
    }

    function isExpiredOrUsed(uint256 _ticketID) external view returns (bool) {
        require(tickets[_ticketID].holder != address(0), "TicketNFT: ticket does not exist");
        return (tickets[_ticketID].expiryTime < block.timestamp || tickets[_ticketID].used == true);
    }
}
