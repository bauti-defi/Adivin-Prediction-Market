
# Adivin Prediction Market

An EVM based prediction market. Users deposit their wager in an Escrow contract in exchange for an ERC1155 token representation of their bet. Prediction tokens are tradable on any secondary market (ex: opensean). Once the market expires, an Oracle submits the winning result. Users can then cash out their winnings from the Escrow contract. Cashing out a wager results in the user burning their ERC1155 token and receiving their winnings from the Escrow contract.

## Set up environment

Assuming you already have [Foundry](https://book.getfoundry.sh/) installed on your computer, update it to the latest version:

```bash
foundryup
```

Also, make sure to run `yarn` to install all the dependencies.

## How to Deploy

Create a `.env` file in the root directory. Use `.env.example` as a template

Deploy the contract factory
    
```bash
forge script script/FactoryDeployer.s.sol:FactoryDeployer --rpc-url $MUMBAI_RPC_URL --broadcast 
```

`MUMBAI_RPC_URL` can be replaced with `MAINNET_RPC_URL` if you want to deploy to mainnet.

## How to verify source code on polygonscan

Contract source code verification will have to be done manually on Polygonscan.

First, run `yarn flatten` to flatten the contracts. This will create a `flattened` directory with the flattened contracts.

Then, go to [Polygonscan](https://polygonscan.com/verifyContract) and verify the contracts. Make sure to select "Single File" and "Solidity Compiler" `0.8.17` for the compiler version.

When prompted for the source, copy and paste the contents of `flattened/Factory.flattened.sol` into the text box.

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