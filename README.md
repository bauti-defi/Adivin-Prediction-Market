
# Adivin Prediction Market

An EVM based prediction market. Users deposit their wager in an Escrow contract in exchange for an ERC1155 token representation of their bet. Prediction tokens are tradable on any secondary market (ex: opensean). Once the market expires, an Oracle submits the winning result. Users can then cash out their winnings from the Escrow contract. Cashing out a wager results in the user burning their ERC1155 token and receiving their winnings from the Escrow contract.

## Design Spec

### Actors

- Administrator
- User
- Oracle

#### Administrator

**Actions**
- Create Market
- Open Market
- Pause Market
- Set Oracle
- Set Escrow


#### User

**Actions**
- Place Bet
- Cashout Bet

#### Oracle

**Actions**
- Set Market Result (MarketState == FINISHED)

### Contracts
- Factory: Creates markets 
- PredictionMarket: ERC1155 wrapper representing a prediction
- Escrow: Holds all wagers

### Diagrams
[Sequence Diagram](/diagrams/Adivin%20Sequence%20diagram.png)

[Flow Diagram](/diagrams/Adivin%20Flow.png)