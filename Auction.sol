// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

/**
 * @title Auction Contract
 * @author Iván
 * @notice Smart contract for managing auctions with bids, deposits, and refunds.
*/

contract Auction {

    // ========== STATE VARIABLES ==========

    /// @dev Contract owner
    address private owner;

    /// @dev Timestamp when the auction ends (can be extended)
    uint256 public auctionTime;
    
    /// @dev Boolean indicating if the auction is currently active
    bool public auctionActive;

    /// @dev Amount of the current highest offer and bidder
    uint256 private bestOffer;
    address private bestBidder;

    /// @dev Constants
    uint256 private constant MINIMUM_INCREMENT = 5;
    uint256 private constant GAS_COMMISSION = 2;
    uint256 private constant AUCTION_EXTENSION = 10 minutes;

    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor that initializes the contract.
     * @notice Sets up a new auction with 10 minutes duration and activates it.
     * The deployer becomes the owner of the auction.
     */
    constructor() {
        owner = msg.sender;
        auctionTime = block.timestamp + 10 minutes;
        auctionActive = true;
    }

    // ========== DATA STRUCTURES ==========

    /**
     * @dev Data structure to store offers.
     * @param bidder The address of the bidder.
     * @param offer The amount of the offer.
     * @param offerMoment The timestamp of the offer.
     */
    struct Offer {
        address bidder;
        uint256 offer;
        uint256 offerMoment;
    }

    /// @dev Mapping to store the balance of each bidder.
    mapping(address => uint256) private balance;

    /// @dev Arrays to store the offers and the bidders.
    Offer[] public offers;
    address[] public uniqueBidders;

    // ========== MODIFIERS ==========

    /**
     * @dev Modifier to check if the caller is the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
     * @dev Modifier to check if the auction is active.
     */
    modifier auctionInProgress() {
        require(auctionActive == true, "Auction inactive");
        _;
    }

    /**
     * @dev Modifier to check if the auction is finished.
     */
    modifier auctionFinished() {
        require(auctionActive == false, "Auction active");
        _;
    }

    // ========== OFFER FUNCTION ==========

    /**
     * @dev Function to make an offer.
     * @notice The offer must be greater than the minimum offer (5% increment).
     * The function automatically handles bid validation, bidder registration, and auction time extension.
     * @param None - Uses msg.value as the bid amount and msg.sender as the bidder.
     * @custom:requirements 
     * - Auction must be active
     * - Bid amount must be at least 5% higher than current best offer
     * - Must send ETH with the transaction
     */
    function makeOffer() external auctionInProgress payable {
        uint256 _currentBestOffer = bestOffer;
        uint256 _minimumOffer = _currentBestOffer + (_currentBestOffer * MINIMUM_INCREMENT / 100);
        require(msg.value > _minimumOffer, "Offer too low");

        uint256 _offersLength = offers.length;
        uint256 _valueOffer = msg.value;
        uint256 i;
        address _addrBidder = msg.sender;
        bool _registeredBidder = false;
        
        uint256 _currentBalance = balance[_addrBidder];

        // Check if the bidder is registered.
        for (i = 0; i < _offersLength; i++) {
            if (_addrBidder == offers[i].bidder) {
                offers[i].offer = _valueOffer;
                offers[i].offerMoment = block.timestamp;
                _registeredBidder = true;
                break;
            }
        }

        // If the bidder is not registered, add the offer to the array.
        if (!_registeredBidder) {
            offers.push(Offer(_addrBidder, _valueOffer, block.timestamp));
        }

        // If the bidder is not registered, add the bidder to the array.
        if (_currentBalance == 0) {
            uniqueBidders.push(_addrBidder);
        }

        // Add the offer to the balance of the bidder.
        balance[_addrBidder] = _currentBalance + _valueOffer;
        // Update the best bidder and offer.
        bestBidder = _addrBidder;
        bestOffer = _valueOffer;

        // If the auction is about to end, extend the auction time by 10 minutes.
        uint256 _currentAuctionTime = auctionTime;
        if (block.timestamp >= (_currentAuctionTime - AUCTION_EXTENSION)) {
            auctionTime = block.timestamp + AUCTION_EXTENSION;
        }

        // Emit the event of the new offer.
        emit newOffer(_addrBidder, _valueOffer, block.timestamp);
    }

    // ========== WITHDRAW FUNCTION ==========

    /**
     * @dev Function to return the deposits of the bidders who did not make the best offer.
     * @notice The function can only be called by the owner when the auction is finished.
     * Returns deposits to losing bidders minus gas commission, and transfers remaining balance to owner. 
     * @custom:requirements
     * - Only owner can call this function
     * - Auction must be finished
     * - Contract must have sufficient balance for transfers
     */
    function returnDeposits() external onlyOwner auctionFinished {
        uint256 _uniqueBiddersLength = uniqueBidders.length;
        uint256 _valueReturn;
        uint256 _bestOffer = bestOffer;
        uint256 i;

        // Loop through the bidders and return the deposits of the bidders who did not make the best offer.
        for (i = 0; i < _uniqueBiddersLength; i++) {
            uint256 _currentBalance = balance[uniqueBidders[i]];
            // If the balance of the bidder is less than the best offer, return the deposit.
            if (_currentBalance < _bestOffer) {
                // Calculate the amount to return subtracting the gas commission.
                _valueReturn = _currentBalance - (_currentBalance * GAS_COMMISSION / 100);
                balance[uniqueBidders[i]] = 0;
                payable(uniqueBidders[i]).transfer(_valueReturn);
            }
        }
        payable(owner).transfer(address(this).balance);
    }

    // ========== PARTIAL REFUND FUNCTION ==========

    /**
     * @dev Function to return the bidder's remaining deposits when he made another higher bid.
     * @notice The function can only be called by the bidder when the auction is active.
     * Allows bidders to withdraw excess funds from previous bids while keeping their current bid active.
     * @param None - Uses msg.sender to identify the bidder requesting refund.
     * @custom:requirements
     * - Auction must be active
     * - Caller must have made at least one bid
     * - Caller must have excess funds to withdraw (balance > current bid)
     */
    function partialRefund() external auctionInProgress {
        address _extractor = msg.sender;
        uint256 _offersLength = offers.length;

        bool _offerFound = false;
        uint256 offerIndex;
        uint256 i;

        // Loop through the offers and determine if the bidder has made an offer previously.
        for (i = 0; i < _offersLength; i++) {
            // If the bidder has made an offer previously, break the loop.
            if (offers[i].bidder == _extractor) {
                _offerFound = true;
                offerIndex = i;
                break;
            }
        }

        // If the bidder has not made an offer previously, revert the transaction.
        require(_offerFound, "No offers found");

        // Calculate the amount to return.
        uint256 _currentBalance = balance[_extractor];
        uint256 _valueReturn = _currentBalance - offers[offerIndex].offer;
        // If the amount to return is greater than 0, return the amount.
        require(_valueReturn > 0, "No funds");

        // Subtract the amount to return from the balance of the bidder.
        balance[_extractor] = _currentBalance - _valueReturn;
        payable(_extractor).transfer(_valueReturn);
    }

    // ========== FUNCTION TO END THE AUCTION ==========

    /**
     * @dev Function to end the auction.
     * @notice The function can only be called by the owner when the auction time has expired.
     * @custom:requirements
     * - Only owner can call this function
     * - Current timestamp must be greater than auctionTime
     * @custom:effects
     * - Sets auctionActive to false
     * - Emits auctionFinish event with winner information
     */
    function endAuction() external onlyOwner {
        require(block.timestamp > auctionTime, "Auction active");
        auctionActive = false;
        emit auctionFinish(bestBidder, bestOffer);
    }

    // ========== FUNCTION TO SHOW THE WINNER ==========

    /**
     * @dev Function to show the winner of the auction.
     * @notice View function that returns the current highest bidder and offer amount.
     * @return bestBidder The address of the current winner.
     * @return bestOffer The amount of the current highest offer.
     */
    function showWinner() external view returns (address, uint256) {
        return (bestBidder, bestOffer);
    }

    // ========== FUNCTION TO SHOW THE LIST OF OFFERS ==========

    /**
     * @dev Function to show the list of offers.
     * @notice View function that returns the complete history of all offers made.
     * @return offers Array of Offer structs containing bidder, amount, and timestamp for each offer.
     */
    function offersList() external view returns (Offer[] memory) {
        return offers;
    }

    // ========== EMERGENCY FUNCTION ==========

    /**
     * @dev Function to recover ETH in case of emergency.
     * @notice Only the owner can recover ETH in emergency situations.
     * This function should only be used if there are stuck funds or critical issues.
     * @custom:requirements
     * - Only owner can call this function
     * - Contract must have ETH balance greater than 0
     * @custom:security Critical function
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds");

        payable(owner).transfer(contractBalance);
        emit emergencyWithdrawal(owner, contractBalance);
    }

    // ========== EVENTS ==========

    /**
     * @dev Event to emit when a new offer is made.
     * @param bidder The address of the bidder.
     * @param offer The amount of the offer.
     * @param offerMoment The timestamp of the offer.
     */
    event newOffer(address indexed bidder, uint256 indexed offer, uint256 offerMoment);

    /**
     * @dev Event to emit when the auction is finished.
     * @param bestBidder The address of the winner.
     * @param bestOffer The amount of the best offer.
     */
    event auctionFinish(address indexed bestBidder, uint256 bestOffer);

    /**
     * @dev Event to emit when the emergency withdrawal is executed.
     * @param owner The address of the owner.
     * @param contractBalance The amount of the withdrawal.
     */
    event emergencyWithdrawal(address indexed owner, uint256 contractBalance);

}