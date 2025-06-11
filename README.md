# Auction Smart Contract

I have developed a smart contract that simulates an auction where users can make multiple bids and compete for victory.

## General Description

The `Auction.sol` contract implements a decentralized auction system where:
- People can make bids by sending Ether.
- Each bid must be at least 5% higher than the previous one to be considered a valid bid, otherwise the bid cannot be made.
- The auction automatically extends for 10 minutes when a user makes a bid during the last 10 minutes of the auction.
- When the auction ends, losing bids are returned to users and the winning bid is transferred to the owner.

## State Variables

### Main Variables
- **`owner`**: The address of the user who initialized the auction.
- **`auctionTime`**: Timestamp indicating when the auction ends.
- **`auctionActive`**: A boolean that indicates when the auction is in progress.

### Bid Variables
- **`bestOffer`**: The highest amount that has been bid so far.
- **`bestBidder`**: The address of the user who made the best bid.
- **`balance`**: Records how much Ether each user has deposited.
- **`offers`**: Array that stores all bids made by users as `Offer` structs.
- **`uniqueBidders`**: List of all unique addresses of users who have participated.

### Constants
- **`MINIMUM_INCREMENT`** = 5: Each new bid must be 5% higher than the previous one.
- **`GAS_COMMISSION`** = 2: A 2% commission is charged to cover gas costs.
- **`AUCTION_EXTENSION`** = 10 minutes: Time the auction is extended when there are bids near its end.

## Main Functions

### `constructor()` 
- **Description**: Initializes the contract when deployed.
- **What happens**: 
  - Sets the user who executes the contract as the owner.
  - Sets an initial duration for the auction of 10 minutes.
  - Indicates through a boolean that the auction is active.

### `makeOffer()`
- This function is `payable`, which means it can receive money.
- Only works if the auction is active.
- **Logic**:
  1. Verifies that the new bid is at least 5% higher than the previous best bid.
  2. Updates the values to indicate the new best bid and new best bidder.
  3. If the user has bid before, updates their existing offer; otherwise creates a new offer entry.
  4. Registers the user in the uniqueBidders list if it's their first time bidding.
  5. Updates the user's balance by adding their new bid to their existing balance.
  6. Extends the auction time if the bid occurs near the end of the auction.
  7. Emits an event to indicate that there was a new bid.

### `returnDeposits()`
- Only the owner can execute this function.
- This function can only be executed when the auction is finished.
- **Description**: Returns the bid Ether to users who did not win and transfers the remaining balance to the owner.
- **Logic**:
  1. Verifies all auction participants.
  2. If the user's balance is less than the best bidder's, their Ether is returned.
  3. The 2% commission is deducted to cover gas costs.
  4. The rest of the balance is transferred to the contract owner.

### `partialRefund()`
- Any user who has made at least one bid can call this function while the auction is active.
- **Description**: Allows users to withdraw the excess from their previous deposits.
- **Logic**:
  1. Searches all bids made by the user.
  2. Calculates the difference between their total balance and their current bid.
  3. Returns only the excess, but their current bid remains active.

### `endAuction()`
- Only the owner can execute this function.
- **Description**: Officially ends the auction.
- **Requirement**: Only works after the auction time has expired.
- **Effect**: Indicates that the auction is inactive and emits the auction ended event.

### `showWinner()`
- Being a `view` function, it does not consume gas.
- **Returns**: The address and amount of the auction winner.
- **Description**: Allows querying the winning user and winning amount.

### `offersList()`
- Being a `view` function, it does not consume gas.
- **Returns**: The complete list of bids that have been made.
- **Description**: Allows viewing the complete history of bids made.

### `emergencyWithdraw()`
- Only the owner can execute this function.
- **Description**: Emergency function to recover all ETH from the contract.
- **Purpose**: This function should only be used if there are stuck funds or in extreme circumstances.
- **Logic**:
  1. Checks that there are funds available in the contract.
  2. Transfers all contract balance to the owner.
  3. Emits an emergency withdrawal event.
- **Security**: This is a critical function that should only be used as a last resort.

## Events

### `newOffer` 
- **When emitted**: Every time a valid bid is made.
- **Parameters**: 
  - `bidder`: Who made the bid
  - `offer`: Amount bid
  - `offerMoment`: Timestamp of when it was made

### `auctionFinish`

- **When emitted**: When the owner officially ends the auction.  
- **Parameters**:
  - `bestBidder`: Winner's address
  - `bestOffer`: Winning amount

### `emergencyWithdrawal`

- **When emitted**: When the owner executes an emergency withdrawal.
- **Parameters**:
  - `owner`: Owner's address who executed the withdrawal
  - `contractBalance`: Amount of ETH withdrawn from the contract

## How to use my contract

### To participate in the auction:
1. Use the `makeOffer()` function by sending Ether. This bid must be at least 5% higher than the previous bid.
2. If the user had already bid before and wants to withdraw the Ether from that previous bid, the `partialRefund()` function should be used.
3. By consulting the `showWinner()` function, you can see who is winning.

### For the auction owner, who executes the contract:
1. Must wait for the auction time to end. 
2. Calls the `endAuction()` function to officially deactivate everything.
3. Calls the `returnDeposits()` function so that Ether is returned to losing users.
4. In emergency situations, can use `emergencyWithdraw()` to recover all ETH from the contract.

---
*Developed as part of ETH KIPU Module 2* 