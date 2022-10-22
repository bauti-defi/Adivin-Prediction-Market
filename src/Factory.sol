// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PredictionMarket.sol";
import "./Escrow.sol";

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
    function createMarket(
        uint256 _predictionCount,
        uint256 _marketExpiration,
        address _paymentToken,
        address _resultOracle
    ) public onlyAdmin {
        // TODO: Validate _resultOracle is a valid oracle

        // create market
        PredictionMarket market = new PredictionMarket(_predictionCount, _marketExpiration);

        // Give oracle permissions
        market.grantRole(market.ESCROW_ROLE, _resultOracle);

        // create escrow
        Escrow escrow = new Escrow(_paymentToken, address(market));

        // emit event
        emit PredictionMarketCreated(address(market), address(escrow), msg.sender);
    }
}
