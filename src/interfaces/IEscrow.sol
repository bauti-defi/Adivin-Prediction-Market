// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@src/PredictionMarket.sol";

interface IEscrow {
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

    function createMarket(address market) external;

    // should only be called by contracts (oracles) that have been approved by the owner
    // these contracts should be proxies that decode incoming data streams into (marketId, winningPredictionId) tupples
    // those tupples are the parameters below
    // ? could be a chainlink oracle or multisig
    function submitMarketResult(uint256 marketId, uint256 winningPredictionId) external;
}
