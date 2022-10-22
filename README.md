
# Adivin Prediction Market

## Design Spec

### Actors

- Administrator
- Better
- Oracle

#### Administrator

**Actions**
- Create Market
- Open Market
- Pause Market


#### Better

**Actions**
- Place Bet
- Cashout Bet

#### Oracle

**Actions**
- Set Market Result (MarketState == FINISHED)
- Close betting (MarketState == CLOSED)

### Contracts

#### PredictionMarket

**Actions**
- Mint tokens (only escrow)
- Burn tokens (only escrow)
- Submit result (only oracle)
- Close betting (only oracle)
- Pause betting (only admin)
- unPause betting (only admin)

#### Escrow

**Actions**
- Place bet (only better)
- Cashout bet (only better)
- Start market betting (only admin)
