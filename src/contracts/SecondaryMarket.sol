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

    constructor(address _purchaseTokenAddress) {
        purchaseToken = IERC20(_purchaseTokenAddress);
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
        require(bidAmount > listing.highestBid, "Bid amount is not higher than highest bid");

        if (listing.highestBidder != address(0)) {
            purchaseToken.transferFrom(listing.highestBidder, listing.lister, listing.highestBid);
        }

        purchaseToken.transferFrom(msg.sender, address(this), bidAmount);
        bids[ticketCollection][ticketID] = bidAmount;
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
        require(listing.isActive, "Ticket is not listed");
        require(listing.highestBidder != address(0), "No bids for ticket");

        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        ticketNFT.updateHolderName(ticketID, ""); //fix name later
        ticketNFT.setUsed(ticketID);
        ticketNFT.transferFrom(address(this), listing.highestBidder, ticketID);

        uint256 fee = listing.highestBid * FEE_PERCENTAGE / 100;
        purchaseToken.transferFrom(listing.highestBidder, listing.lister, listing.highestBid - fee);
        purchaseToken.transferFrom(listing.highestBidder, address(this), fee);

        listing.isActive = false;
        listing.highestBid = 0;
        listing.highestBidder = address(0);

        emit BidAccepted(listing.highestBidder, ticketCollection, ticketID, listing.highestBid, "");
    }

    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.isActive, "Ticket is not listed");
        require(listing.lister == msg.sender, "Not the ticket lister");

        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        ticketNFT.transferFrom(address(this), listing.lister, ticketID);

        listing.isActive = false;
        listing.highestBid = 0;
        listing.highestBidder = address(0);

        emit Delisting(ticketCollection, ticketID);
    }
}
