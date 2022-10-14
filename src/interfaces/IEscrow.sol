// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@src/PredictionMarket.sol";

/// @notice Escrow contract is a user facing contract. It manages the lifecycle of Prediction Market(s), escrows
/// the pot of each market and executes the cashout of predictions.
interface IEscrow {
    /// @dev Metadata for a particular Prediction Market
    struct MarketData {
        PredictionMarket market;
        uint256 pot;
    }

    event PredictionMade(uint256 indexed marketId, address buyer, uint256 predictionId, uint256 amount, uint256 pot);
    event PredictionMarketClosed(uint256 indexed marketId, uint256 winningPrediction, address marketAddress);
    event PredictionMarketCreated(uint256 indexed marketId, address marketAddress);

    function buy(uint256 marketId, uint256 predictionId, uint256 amount) external;

    // Users need to personally cashout
    function cashout(uint256 marketId, uint256 predictionId) external;

    function openMarket(address market) external;

    /// @notice Closes a Prediction Market with the given winning prediction.
    /// @dev Caller is expected to be an authorized multisig or oracle (single source of truth)
    function submitMarketResult(uint256 marketId, uint256 winningPredictionId) external;
}
