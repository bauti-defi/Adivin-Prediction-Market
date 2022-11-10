// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PredictionMarket.sol";
import "./Escrow.sol";
import "./interfaces/IFactory.sol";

/// @author bauti.eth
contract Factory is IFactory {
    uint256 public totalMarkets;

    /// @notice Be careful what token you pass in.
    function createMarket(
        string calldata _marketName,
        string calldata _description,
        string calldata _mediaUri,
        uint256 _predictionCount,
        uint256 _marketExpirationDate,
        uint256 _marketResolveDate,
        uint256 _individualTokenSupplyCap,
        address _paymentToken
    ) public returns (address, address) {
        // increment counter
        totalMarkets++;

        // create market
        PredictionMarket market =
        new PredictionMarket(_marketName, _description, _mediaUri, _predictionCount, _marketExpirationDate, _marketResolveDate, _individualTokenSupplyCap);

        // create escrow
        Escrow escrow = new Escrow(msg.sender, _paymentToken, address(market));

        // emit event
        emit PredictionMarketCreated(address(market), address(escrow), msg.sender);

        return (address(market), address(escrow));
    }
}
