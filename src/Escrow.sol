// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IEscrow.sol";
import "@src/PredictionMarket.sol";
import "@src/interfaces/IPredictionMarket.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-contracts/security/ReentrancyGuard.sol";

/// @author bauti.eth
contract Escrow is IEscrow, ReentrancyGuard {
    using SafeERC20 for ERC20;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Escrow: only admin can call this function");
        _;
    }

    uint256 public protocolFee;
    PredictionMarket public immutable market;
    MarketData public marketData;
    ERC20 public immutable paymentToken;
    uint256[] public revSharePartitions;
    address[] public revShareRecipients;
    address public immutable admin;

    constructor(address _token, address _market) {
        paymentToken = ERC20(_token);

        require(_market != address(0), "Escrow: market address is 0");

        market = PredictionMarket(_market);

        require(market.isNotStarted(), "Escrow: market has already started");

        marketData = MarketData({totalDeposited: 0, totalPaidOut: 0});

        // Set admin to EOA
        admin = tx.origin;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ EXTERNAL FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~

    function buy(uint256 _predictionId, uint256 _amount) external override nonReentrant {
        // scale up according to decimals
        uint256 depositAmount = _amount * 10 ** paymentToken.decimals();

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
        if (!isAWinner) revert IncorrectPrediction(_predictionId);

        // Get caller token balance
        uint256 _tokenBalance = market.balanceOf(msg.sender, _predictionId);

        // Check caller has tokens
        if (_tokenBalance == 0) revert InsufficientPredictionTokenBalance(_predictionId);

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
        uint256 _payoutAmount = _tokenBalance * marketData.totalDeposited / _ciruclatingWinningTokens;

        // update state for totalPaidOut and totalDeposited
        marketData.totalPaidOut += _payoutAmount;
        marketData.totalDeposited -= _payoutAmount;

        // transfer the tokens to the caller
        paymentToken.safeTransfer(msg.sender, _payoutAmount);

        // emit
        emit PredictionPaidOut(msg.sender, _payoutAmount);
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ ADMIN FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~

    function setProtocolFee(uint256 _protocolFee) external override onlyAdmin {
        if (_protocolFee >= 100) revert InvalidProtocolFee(_protocolFee);

        uint256 oldFee = protocolFee;
        protocolFee = _protocolFee;

        // emit
        emit ProtocolFeeUpdated(oldFee, _protocolFee);
    }

    function setRevShareRecipients(address[] calldata _recipients, uint256[] calldata _shares) external override onlyAdmin {
        require(_recipients.length == _shares.length, "Escrow: recipients and shares arrays must be the same length");
        require(_recipients.length > 0, "Escrow: recipients and shares arrays must be greater than 0");

        // check if shares sum to 100
        uint256 _totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            _totalShares += _shares[i];
        }

        if (_totalShares != 100) revert InvalidRevShareSum();

        // update state
        revShareRecipients = _recipients;
        revSharePartitions = _shares;

        // emit
        emit RevShareParticipantsUpdated(revShareRecipients, revSharePartitions);
    }

    function clearRevShareRecipients() external override onlyAdmin {
        // update state
        revShareRecipients = new address[](0);
        revSharePartitions = new uint256[](0);

        // emit
        emit RevShareParticipantsCleared();
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ GETTERS ~~~~~~~~~~~~~~~~~~~~~~

    function totalPaidOut() external view override returns (uint256) {
        return marketData.totalPaidOut;
    }

    function totalDeposited() external view override returns (uint256) {
        return marketData.totalDeposited;
    }
}
