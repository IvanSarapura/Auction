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
- **`propietario`**: The address of the user who initialized the auction.
- **`tiempoSubasta`**: Timestamp indicating when the auction ends.
- **`subastaActiva`**: A boolean that indicates when the auction is in progress.

### Bid Variables
- **`mejorOferta`**: The highest amount that has been bid so far.
- **`mejorOfertante`**: The address of the user who made the best bid.
- **`balance`**: Records how much Ether each user has deposited.
- **`ofertas`**: Array that stores in a list all the bids made by users.
- **`ofertantesUnicos`**: List of all addresses of users who have participated.

### Constants
- **`INCREMENTO_MINIMO`** = 5: Each new bid must be 5% higher than the previous one.
- **`COMISION_GAS`** = 2: A 2% commission is charged to cover gas costs.
- **`EXTENSION_OFERTA`** = 10 minutes: Time the auction is extended when there are bids near its end.

## Main Functions

### `constructor()` 
- **Description**: Initializes the contract when deployed.
- **What happens**: 
  - Sets the user who executes the contract as the owner.
  - Sets an initial duration for the auction of 10 minutes.
  - Indicates through a boolean that the auction is active.

### `ofertar()`
- This function is `payable`, which means it can receive money.
- Only works if the auction is active.
- **Logic**:
  1. Verifies that the new bid is at least 5% higher than the previous best bid.
  2. Updates the values to indicate the new best bid and new best bidder.
  3. Registers the user if it's the first time they make a bid.
  4. Updates the user's balance by adding their new bid.
  5. Extends the auction time if the bid occurs near the end of the auction.
  6. Emits an event to indicate that there was a new bid.

### `devolverDepositos()`
- Only the owner can execute this function.
- This function can only be executed when the auction is active.
- **Description**: Returns the bid Ether to users who did not win.
- **Logic**:
  1. Verifies all auction participants.
  2. If the user's balance is less than the best bidder's, their Ether is returned.
  3. The 2% commission is deducted to cover gas costs.
  4. The rest of the balance is transferred to the contract owner.

### `reembolsoParcial()`
- Any user can call this function while the auction is active.
- **Description**: Allows users to withdraw the excess from their previous deposits.
- **Logic**:
  1. Searches all bids made by the user.
  2. Calculates the difference between their total balance and their current bid.
  3. Returns only the excess, but their current bid remains active.

### `terminarSubasta()`
- Only the owner can execute this function.
- **Description**: Officially ends the auction.
- **Requirement**: Only works after the auction time has expired.
- **Effect**: Indicates that the auction is inactive and emits the auction ended event.

### `mostrarGanador()`
- Being a `view` function, it does not consume gas.
- **Returns**: The address and amount of the auction winner.
- **Description**: Allows querying the winning user and winning amount.

### `listaOfertas()`
- Being a `view` function, it does not consume gas.
- **Returns**: The complete list of bids that have been made.
- **Description**: Allows viewing the complete history of bids made.

## Events

### `nuevaOferta` 
- **When emitted**: Every time a valid bid is made.
- **Parameters**: 
  - `ofertante`: Who made the bid
  - `oferta`: Amount bid
  - `momentoOferta`: Timestamp of when it was made

### `subastaFinalizada`

- **When emitted**: When the owner officially ends the auction.  
- **Parameters**:
  - `mejorOfertante`: Winner's address
  - `mejorOferta`: Winning amount

## How to use my contract

### To participate in the auction:
1. Use the `ofertar()` function by sending Ether. This bid must be at least 5% higher than the previous bid.
2. If the user had already bid before and wants to withdraw the Ether from that previous bid, the `reembolsoParcial()` function should be used.  
3. By consulting the `mostrarGanador()` function, you can see who is winning.

### For the auction owner, who executes the contract:
1. Must wait for the auction time to end. 
2. Calls the `terminarSubasta()` function to officially deactivate everything.
3. Calls the `devolverDepositos()` function so that Ether is returned to losing users.

---
*Developed as part of ETH KIPU Module 2* 