// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITicketNFT} from "../interfaces/ITicketNFT.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPrimaryMarket} from "../interfaces/IPrimaryMarket.sol";
import {PurchaseToken} from "./PurchaseToken.sol";

contract PrimaryMarket is IPrimaryMarket {
    IERC20 public paymentToken;
    
    struct EventDetails {
        address eventCreator;
        uint256 price;
        uint256 maxTickets;
        uint256 ticketsSold;
    }

    mapping(address => EventDetails) public eventDetails;

    constructor(PurchaseToken _purchaseToken) {
        paymentToken = IERC20(address(_purchaseToken));
    }

    function createNewEvent(string memory eventName, uint256 price, uint256 maxNumberOfTickets) external override returns (ITicketNFT ticketCollection) {
        TicketNFT newTicketNFT = new TicketNFT(eventName, msg.sender, price, maxNumberOfTickets, address(this));

        eventDetails[address(newTicketNFT)] = EventDetails({
            price: price,
            maxTickets: maxNumberOfTickets,
            eventCreator: msg.sender,
            ticketsSold: 0
        });

        emit EventCreated(msg.sender, address(newTicketNFT), eventName, price, maxNumberOfTickets);
        return ITicketNFT(address(newTicketNFT));
    }

    function purchase(address ticketCollection, string memory holderName) external override returns (uint256 id) {
        EventDetails storage details = eventDetails[ticketCollection];
        require(details.eventCreator != address(0), "PrimaryMarket: Invalid event");
        require(details.maxTickets > details.ticketsSold, "PrimaryMarket: No tickets available");
        require(paymentToken.balanceOf(msg.sender) >= details.price && paymentToken.allowance(msg.sender, address(this)) >= details.price, "PrimaryMarket: Insufficient funds or allowance");
        paymentToken.transferFrom(msg.sender, details.eventCreator, details.price);
        //Mint the ticket and update tickets sold
        uint256 ticketId = TicketNFT(ticketCollection).mint(msg.sender, holderName);
        details.ticketsSold++;

        emit Purchase(msg.sender, ticketCollection, ticketId, holderName);

        return ticketId;
    }

    function getPrice(address ticketCollection) external view override returns (uint256 price) {
        EventDetails memory details = eventDetails[ticketCollection];
        require(details.eventCreator != address(0), "PrimaryMarket: Event does not exist");
        return details.price;
    }

}
