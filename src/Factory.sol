// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PredictionMarket.sol";
import "./interfaces/IPredictionMarket.sol";
import "./Escrow.sol";
import "./interfaces/IFactory.sol";

/// @author bauti.eth
contract Factory is IFactory {
    uint256 public totalMarkets;

    /// @notice Be careful what token you pass in.
    function createMarket(Parameters calldata parameters) public returns (address, address) {
        // copy it into memory to avoid stack too deep
        Parameters memory _parameters = parameters;

        // increment counter
        totalMarkets++;

        // create market
        PredictionMarket market = new PredictionMarket(
            _parameters._marketName, 
            _parameters._description, 
            _parameters._mediaUri, 
            _parameters._marketExpirationDate, 
            _parameters._marketResolveDate, 
            _parameters._individualTokenSupplyCap,
            _parameters._tokenNames, 
            _parameters._tokenColors
        );

        // create escrow
        Escrow escrow = new Escrow(msg.sender, _parameters._paymentToken, address(market));

        // emit event
        emit PredictionMarketCreated(address(market), address(escrow), msg.sender);

        return (address(market), address(escrow));
    }
}
