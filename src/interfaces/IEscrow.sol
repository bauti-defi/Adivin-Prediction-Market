// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@src/PredictionMarket.sol";

/// @author bauti.eth
/// @notice Escrow contract is a user facing contract. It manages the lifecycle the Prediction Market, escrows
/// the pot and executes the cashout of winning bets.
interface IEscrow {
    /// @dev Metadata for a particular Prediction Market
    struct MarketData {
        uint256 totalDeposited;
        uint256 totalPaidOut;
        PredictionMarket market;
    }

    event PredictionMade(address indexed buyer, uint256 predictionId, uint256 amount, uint256 pot);
    event PredictionPaidOut(address indexed claimer, uint256 amount);

    function buy(uint256 _predictionId, uint256 _amount) external;

    // Users need to personally cashout
    function cashout(uint256 _predictionId) external;
}
