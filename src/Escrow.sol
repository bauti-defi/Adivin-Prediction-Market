// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IEscrow.sol";
import "@src/PredictionMarket.sol";
import "@src/interfaces/IPredictionMarket.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-contracts/security/ReentrancyGuard.sol";

contract Escrow is IEscrow, ReentrancyGuard {
    using SafeERC20 for ERC20;

    PredictionMarket public immutable market;
    MarketData public marketData;
    ERC20 public immutable paymentToken;

    constructor(address _token, address _market) {
        paymentToken = ERC20(_token);

        require(_market != address(0), "Escrow: market address is 0");

        market = PredictionMarket(_market);

        require(market.isNotStarted(), "Escrow: market has already started");

        marketData = MarketData({market: market, totalDeposited: 0, totalPaidOut: 0});
    }

    function buy(uint256 _predictionId, uint256 _amount) external override nonReentrant {
        // scale up according to decimals
        uint256 depositAmount = _amount * paymentToken.decimals();

        // check if we have enough allowance
        require(paymentToken.allowance(msg.sender, address(this)) >= depositAmount, "Escrow: insufficient allowance");

        // transfer their stables into the escrow
        paymentToken.safeTransferFrom(msg.sender, address(this), depositAmount);

        // mint option tokens to the msg.sender
        // ! amount is not scaled
        market.mint(msg.sender, _predictionId, _amount);

        // update totalDeposited
        marketData.totalDeposited += depositAmount;

        // emit event
        emit PredictionMade(msg.sender, _predictionId, _amount, marketData.totalDeposited);
    }

    function cashout(uint256 _predictionId) external override nonReentrant {
        // Check it is finished
        require(market.isFinished(), "Escrow: Market is not finished");

        // Check if prediction is winning
        bool isAWinner = market.isWinner(_predictionId);

        // Only winners can cashout, save noobs the gas fee
        require(isAWinner, "Escrow: Prediction is not a winner");

        // Get caller token balance
        uint256 _tokenBalance = market.balanceOf(msg.sender, _predictionId);

        // Check caller has tokens
        require(_tokenBalance > 0, "Escrow: Caller has no tokens");

        // Get the circulating supply of winning tokens
        // ! notice burned tokens are not accounted for
        uint256 _ciruclatingWinningTokens = market.totalSupply(_predictionId);

        // burn ALL their tokens
        // ! notice burn() already checks if caller has given escrow allowance
        market.burn(msg.sender, _predictionId, _tokenBalance);

        // check the tokens were burned
        require(market.balanceOf(msg.sender, _predictionId) == 0, "Escrow: Tokens were not burned");

        // calculate the amount to pay out, scale the value
        // the winner is paid a proportionate amount of the totalDeposited
        // winnerBalance/circulatingWinningSupply * totalDeposited
        uint256 _payoutAmount =
            _tokenBalance * paymentToken.decimals() * marketData.totalDeposited / _ciruclatingWinningTokens;

        // update state for totalPaidOut and totalDeposited
        marketData.totalPaidOut += _payoutAmount;
        marketData.totalDeposited -= _payoutAmount;

        // transfer the tokens to the caller
        paymentToken.safeTransfer(msg.sender, _payoutAmount);

        // emit
        emit PredictionPaidOut(msg.sender, _payoutAmount);
    }

}
