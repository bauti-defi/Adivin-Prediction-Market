// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @author bauti.eth
interface IFactory {
    /// @notice Emitted when the factory creates a new Escrow-PredictionMarket pair.
    event PredictionMarketCreated(address indexed market, address indexed escrow, address indexed creator);

    /// @notice Creates a new prediction market that is NOT OPEN.
    function createMarket(uint256 _predictionCount, uint256 _marketExpiration, address _paymentToken) external;
}
