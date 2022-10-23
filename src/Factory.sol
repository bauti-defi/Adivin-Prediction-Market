// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PredictionMarket.sol";
import "./Escrow.sol";
import "./interfaces/IFactory.sol";

/// @author bauti.eth
contract Factory is IFactory {
    address immutable admin;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createMarket(uint256 _predictionCount, uint256 _marketExpiration, address _paymentToken)
        public
        onlyAdmin
    {
        // create market
        PredictionMarket market = new PredictionMarket(_predictionCount, _marketExpiration);

        // create escrow
        Escrow escrow = new Escrow(_paymentToken, address(market));

        // emit event
        emit PredictionMarketCreated(address(market), address(escrow), msg.sender);
    }
}
