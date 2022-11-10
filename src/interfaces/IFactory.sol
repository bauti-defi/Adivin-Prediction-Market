// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @author bauti.eth
interface IFactory {
    error NotAdmin();

    /// @notice Emitted when the factory creates a new Escrow-PredictionMarket pair.
    event PredictionMarketCreated(address indexed market, address indexed escrow, address indexed creator);

    /// @notice Creates a new prediction market that is NOT OPEN.
    /// @notice Only admin role is set on the market. Oracle and Escrow roles need to be set manually by the admin.
    function createMarket(
        string calldata _marketName,
        string calldata _description,
        string calldata _mediaUri,
        uint256 _predictionCount,
        uint256 _marketExpiration,
        uint256 _marketResolveDate,
        uint256 _individualTokenSupplyCap,
        address _paymentToken
    ) external returns (address, address);
}
