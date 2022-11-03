// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PredictionMarket.sol";
import "./Escrow.sol";
import "./interfaces/IFactory.sol";

/// @author bauti.eth
contract Factory is IFactory {
    uint256 public totalMarkets;
    address immutable admin;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Be careful what token you pass in. That is why this is admin only.
    function createMarket(
        uint256 _predictionCount,
        uint256 _marketExpiration,
        uint256 _individualTokenSupplyCap,
        address _paymentToken
    ) public onlyAdmin returns (address, address) {
        // increment counter
        totalMarkets++;

        // create market
        PredictionMarket market = new PredictionMarket(_predictionCount, _marketExpiration, _individualTokenSupplyCap);

        // create escrow
        Escrow escrow = new Escrow(msg.sender, _paymentToken, address(market));

        // emit event
        emit PredictionMarketCreated(address(market), address(escrow), msg.sender);

        return (address(market), address(escrow));
    }
}
