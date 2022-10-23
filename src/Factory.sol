// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PredictionMarket.sol";
import "./Escrow.sol";

/// @author bauti.eth
contract Factory {
    event PredictionMarketCreated(address indexed market, address indexed escrow, address indexed creator);

    address immutable admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Factory: only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Creates a new prediction market that is NOT OPEN.
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
