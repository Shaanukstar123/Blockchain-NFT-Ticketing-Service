// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {ITicketNFT} from "../interfaces/ITicketNFT.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPrimaryMarket} from "../interfaces/IPrimaryMarket.sol";

contract PrimaryMarket is IPrimaryMarket {
    IERC20 public paymentToken;

    // State variables to track events, prices, etc.

    constructor(address _paymentTokenAddress) {
        paymentToken = IERC20(_paymentTokenAddress);
    }

    function createNewEvent(string memory eventName, uint256 price, uint256 maxNumberOfTickets) external override returns (ITicketNFT ticketCollection) {
        // Logic to create a new TicketNFT contract and store event details
        // Emit EventCreated event
        //instantiate new TicketNFT contract
        TicketNFT newTicketNFT = new TicketNFT();

    }

    function purchase(address ticketCollection, string memory holderName) external override returns (uint256 id) {
        // Logic for purchasing a ticket
        // Emit Purchase event
    }

    function getPrice(address ticketCollection) external view override returns (uint256 price) {
        // Return the price for the given ticket collection
    }

    // Additional helper functions and internal logic
}
