// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IEscrow.sol";
import "@src/PredictionMarket.sol";
import "@src/interfaces/IPredictionMarket.sol";
import "@openzeppelin-contracts/access/AccessControl.sol";
import "@openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin-contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-contracts/security/ReentrancyGuard.sol";

contract Escrow is IEscrow, ERC1155Holder, AccessControl, ReentrancyGuard {
    using SafeERC20 for ERC20;

    bytes32 public constant MARKET_OPENER_ROLE = keccak256("MARKET_OPENER_ROLE");
    bytes32 public constant MARKET_CLOSER_ROLE = keccak256("MARKET_CLOSER_ROLE");

    uint256 public marketIdNonce;
    ERC20 public immutable paymentToken;
    mapping(uint256 => MarketData) markets;

    constructor(address token) {
        // set EOA as admin
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        // set EOA as market creator
        _setupRole(MARKET_OPENER_ROLE, tx.origin);
        paymentToken = ERC20(token);
    }

    function openMarket(address market) external override onlyRole(MARKET_OPENER_ROLE) {
        PredictionMarket marketContract = PredictionMarket(market);

        require(marketContract.isOpen(), "Escrow: market must be open");

        markets[marketIdNonce++] = MarketData({market: marketContract, pot: 0});

        emit PredictionMarketCreated(marketIdNonce - 1, market);
    }

    function submitMarketResult(uint256 marketId, uint256 winningPrediction)
        external
        override
        onlyRole(MARKET_CLOSER_ROLE)
    {
        PredictionMarket marketContract = markets[marketId].market;

        require(marketContract.state() != IPredictionMarket.MarketState.UNDEFINED, "Escrow: Market is undefined");

        // close market and register the winning option
        marketContract.closeMarket(winningPrediction);

        emit PredictionMarketClosed(marketId, winningPrediction, address(marketContract));
    }

    function buy(uint256 marketId, uint256 predictionId, uint256 amount) external override nonReentrant {
        // scale up according to decimals
        uint256 depositAmount = amount * paymentToken.decimals();

        // transfer their stables into the escrow
        paymentToken.safeTransferFrom(msg.sender, address(this), depositAmount);

        // Fetch the market from storage
        MarketData memory marketData = markets[marketId];

        // Check it is defined
        require(marketData.market.state() != IPredictionMarket.MarketState.UNDEFINED, "Escrow: Market is undefined");

        // update pot
        marketData.pot += depositAmount;

        // mint option tokens to the msg.sender
        // ! amount is not scaled
        marketData.market.mint(msg.sender, predictionId, amount);

        // Upsert market into storage
        markets[marketId] = marketData;

        // emit event
        emit PredictionMade(marketId, msg.sender, predictionId, amount, marketData.pot);
    }

    function cashout(uint256 marketId, uint256 predictionId) external override nonReentrant {
        // update token balance for escrow
        // receive option tokens from the msg.sender
        // send stables to the msg.sender
        // emit
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
