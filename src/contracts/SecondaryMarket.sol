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
    uint256 public constant feePercentage = 5;

    struct TicketListing {
        address originalLister;
        address lister;
        uint256 price;
        uint256 highestBid;
        address highestBidder;
        string highestBidderName;
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
        require(ticketNFT.holderOf(ticketID) == msg.sender || ticketNFT.getApproved(ticketID) == msg.sender, "Ticket lister not approved");
        require(!ticketNFT.isExpiredOrUsed(ticketID), "SecondaryMarket: Ticket is expired or used");

        ticketNFT.transferFrom(msg.sender, address(this), ticketID);
        listings[ticketCollection][ticketID] = TicketListing({
            originalLister: msg.sender,
            lister: address(this), //secondary market
            price: price,
            highestBid: price,
            highestBidder: address(0),
            highestBidderName: "",
            isActive: true
        });

        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }

    function submitBid(address ticketCollection, uint256 ticketID, uint256 bidAmount, string memory name) external override {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.isActive, "SecondaryMarket: Ticket is not listed");
        require(bidAmount > listing.highestBid, "SecondaryMarket: Bid not higher than current highest");

        //refund the previous highest bid if it exists
        if (listing.highestBidder != address(0) && listing.highestBid > 0) {
            require(purchaseToken.transfer(listing.highestBidder, listing.highestBid), "SecondaryMarket: Refund failed");
        }
        //transfers new bid to this contract
        require(purchaseToken.transferFrom(msg.sender, address(this), bidAmount), "SecondaryMarket: Transfer failed");

        //update with new highest bid
        listing.highestBid = bidAmount;
        listing.highestBidder = msg.sender;
        listing.highestBidderName = name;

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
        require(listing.isActive, "SecondaryMarket: Ticket not listed");
        require(listing.originalLister == msg.sender, "SecondaryMarket: Not ticket lister to accept bid");
        require(listing.highestBidder != address(0), "SecondaryMarket: No bids available");
        //check balance directly because secondary market has the ticket.
        require(purchaseToken.balanceOf(listing.lister) >= listing.highestBid, "SecondaryMarket: Insufficient balance");
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        address eventCreator = ticketNFT.creator();
        string memory newHolderName = listing.highestBidderName;
        ticketNFT.updateHolderName(ticketID, newHolderName);
        ticketNFT.transferFrom(listing.lister, listing.highestBidder, ticketID);

        uint256 fee = listing.highestBid * feePercentage / 100;
        require(purchaseToken.balanceOf(listing.lister) >= listing.highestBid, "SecondaryMarket: Contract balance insufficient");

        require(purchaseToken.transfer(listing.originalLister, listing.highestBid - fee), "SecondaryMarket: Transfer to lister failed");

        //transfer fee to event creator
        require(purchaseToken.transfer(eventCreator, fee), "SecondaryMarket: Fee transfer failed");

        listing.isActive = false;
        listing.highestBid = 0;
        listing.highestBidder = address(0);
        emit BidAccepted(listing.highestBidder, ticketCollection, ticketID, listing.highestBid, "");
    }

    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        bool isExpired = ticketNFT.isExpiredOrUsed(ticketID);
        require(listing.isActive, "SecondaryMarket: Ticket not listed");
        require(listing.originalLister == msg.sender || isExpired, "SecondaryMarket: Not ticket lister or ticket not expired");

        if (listing.highestBidder != address(0) && listing.highestBid > 0) {
            // Refund the highest bid if there is one
            require(purchaseToken.transfer(listing.highestBidder, listing.highestBid), "SecondaryMarket: Refund failed");
        }

        ticketNFT.transferFrom(listing.lister, listing.originalLister, ticketID);

        listing.isActive = false;
        listing.highestBid = 0;
        listing.highestBidder = address(0);

        emit Delisting(ticketCollection, ticketID);
    }
}
