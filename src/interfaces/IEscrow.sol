// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@src/PredictionMarket.sol";

/// @author bauti.eth
/// @notice Escrow contract is a user facing contract. It manages the lifecycle the Prediction Market, escrows
/// the pot and executes the cashout of winning bets.
interface IEscrow {
    /// @dev Metadata for a particular Prediction Market
    struct MarketData {
        uint256 totalDeposited;
        uint256 totalPaidOut;
        uint256 totalFee;
    }

    /// @dev Emitted when user tries to cashout an incorrect prediction
    error IncorrectPrediction(uint256 predictionId);

    /// @dev Emitted when a user tries to cashout a token they do not have
    error InsufficientPredictionTokenBalance(uint256 predictionId);

    /// @dev Emitted when a fee outside of the range [0, 100) is set
    error InvalidMarketFee(uint256 invalidProtocolFee);

    /// @dev Emitted when a rev share array sum is not equal to 100
    error InvalidRevShareSum();

    event PredictionMade(address indexed buyer, uint256 predictionId, uint256 amount, uint256 pot);
    event PredictionPaidOut(address indexed claimer, uint256 amount);
    event MarketFeeUpdated(uint256 oldFee, uint256 newFee);
    event RevShareParticipantsUpdated(address[] participants, uint256[] shares);
    event RevShareParticipantsCleared();
    event RevSharePaidOut(address indexed recipient, uint256 amount);

    function totalDeposited() external view returns (uint256);

    function totalPaidOut() external view returns (uint256);

    function totalFee() external view returns (uint256);

    function getRevShareRecipients() external view returns (address[] memory);

    function getRevSharePartitions() external view returns (uint256[] memory);

    function setMarketFee(uint256 _newFee) external;

    function setRevShareRecipients(address[] calldata _recipients, uint256[] calldata _shares) external;

    function clearRevShareRecipients() external;

    /// @dev Buy into the prediction market. The payment tokens are escrowed in exchange for
    /// prediction tokens.
    function buy(uint256 _predictionId, uint256 _amount) external;

    /// @dev Claim your winnings. The winning prediction tokens are burned and the payment tokens are
    /// transferred to the claimer.
    /// @notice Reverts if the prediction is not winning.
    function cashout(uint256 _predictionId) external;

    /// @notice only callable by admin OR rev share recipient.
    /// Distributes the current total fees to the rev share recipients.
    function payoutFees() external;
}
