// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@src/PredictionMarket.sol";

/// @notice Escrow contract is a user facing contract. It manages the lifecycle of Prediction Market(s), escrows
/// the pot of each market and executes the cashout of predictions.
interface IEscrow {
    /// @dev Metadata for a particular Prediction Market
    struct MarketData {
        uint256 totalDeposited;
        uint256 totalPaidOut;
        PredictionMarket market;
    }

    event PredictionMade(address indexed buyer, uint256 predictionId, uint256 amount, uint256 pot);
    event PredictionPaidOut(address indexed claimer, uint256 amount);
    event PredictionMarketBettingStarted(address indexed marketAddress);

    function buy(uint256 _predictionId, uint256 _amount) external;

    // Users need to personally cashout
    function cashout(uint256 _predictionId) external;
}
