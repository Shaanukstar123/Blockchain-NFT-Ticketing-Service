// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ITicketNFT} from "../interfaces/ITicketNFT.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPrimaryMarket} from "../interfaces/IPrimaryMarket.sol";
import {PurchaseToken} from "./PurchaseToken.sol";
import {ISecondaryMarket} from "../interfaces/ISecondaryMarket.sol";

contract SecondaryMarket is ISecondaryMarket {
    IERC20 public purchaseToken;
    uint256 public constant FEE_PERCENTAGE = 5;

    struct TicketListing {
        address lister;
        uint256 price;
        uint256 highestBid;
        address highestBidder;
        bool isActive;
    }

    // Mapping from ticket collection address and ticket ID to its listing
    mapping(address => mapping(uint256 => TicketListing)) public listings;

    // Mapping from ticket collection address and ticket ID to bid amounts
    mapping(address => mapping(uint256 => uint256)) public bids;

    constructor(PurchaseToken _purchaseToken) {
        purchaseToken = IERC20(address(_purchaseToken));
    }

    function listTicket(address ticketCollection, uint256 ticketID, uint256 price) external override {
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        require(ticketNFT.holderOf(ticketID) == msg.sender, "Not the ticket owner");
        require(!ticketNFT.isExpiredOrUsed(ticketID), "Ticket is expired or used");

        ticketNFT.transferFrom(msg.sender, address(this), ticketID);
        listings[ticketCollection][ticketID] = TicketListing({
            lister: msg.sender,
            price: price,
            highestBid: 0,
            highestBidder: address(0),
            isActive: true
        });

        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }

    function submitBid(address ticketCollection, uint256 ticketID, uint256 bidAmount, string memory name) external override {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.isActive, "Ticket is not listed");
        require(bidAmount > listing.highestBid, "Bid not higher than current highest");
        require(purchaseToken.allowance(msg.sender, address(this)) >= bidAmount, "Submit bid: Insufficient allowance");

        if (listing.highestBidder != address(0) && listing.highestBid > 0) {
            // Refund the previous highest bid
            require(purchaseToken.transfer(listing.highestBidder, listing.highestBid), "Refund failed");
        }

        purchaseToken.transferFrom(msg.sender, address(this), bidAmount);
        listing.highestBid = bidAmount;
        listing.highestBidder = msg.sender;

        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);
    }



    function getHighestBid(address ticketCollection, uint256 ticketId) external view override returns (uint256) {
        return listings[ticketCollection][ticketId].highestBid;
    }

    function getHighestBidder(address ticketCollection, uint256 ticketId) external view override returns (address) {
        return listings[ticketCollection][ticketId].highestBidder;
    }

    function acceptBid(address ticketCollection, uint256 ticketID) external override {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.isActive, "Ticket not listed");
        require(listing.lister == msg.sender, "Not ticket lister");
        require(listing.highestBidder != address(0), "No bids available");
        require(purchaseToken.allowance(listing.highestBidder, address(this)) >= listing.highestBid, "Accept Bid: Insufficient allowance");

        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        address eventCreator = ticketNFT.creator();
        ticketNFT.updateHolderName(ticketID, ""); // Placeholder for actual name update
        ticketNFT.transferFrom(address(this), listing.highestBidder, ticketID);

        uint256 fee = listing.highestBid * FEE_PERCENTAGE / 100;

        // Ensure the contract has enough tokens to perform the transfer
        require(purchaseToken.balanceOf(address(this)) >= listing.highestBid, "Contract balance insufficient");

        // Transfer bid amount minus fee to lister
        require(purchaseToken.transfer(listing.lister, listing.highestBid - fee), "Transfer to lister failed");

        // Transfer fee to event creator
        require(purchaseToken.transfer(eventCreator, fee), "Fee transfer failed");

        listing.isActive = false;
        listing.highestBid = 0;
        listing.highestBidder = address(0);

        emit BidAccepted(listing.highestBidder, ticketCollection, ticketID, listing.highestBid, "");
    }



    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.isActive, "Ticket not listed");
        require(listing.lister == msg.sender, "Not the ticket lister");

        if (listing.highestBidder != address(0) && listing.highestBid > 0) {
            // Refund the highest bid if there is one
            require(purchaseToken.transfer(listing.highestBidder, listing.highestBid), "Refund failed");
        }

        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        ticketNFT.transferFrom(address(this), listing.lister, ticketID);

        listing.isActive = false;
        listing.highestBid = 0;
        listing.highestBidder = address(0);

        emit Delisting(ticketCollection, ticketID);
    }
}
