// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @author bauti.eth
/// @notice IPredictionMarket is ERC1155 wrapper impementation
interface IPredictionMarket {
    error InvalidPredictionId(uint256 predictionId);
    error MarketNotOpen();
    error MarketNotClosed();
    error MaximumSupplyReached(uint256 tokenId);

    /// @notice Emitted when a prediction result is submitted by oracle
    event ResultSubmitted(uint256 indexed predictionId, uint256 timestamp);

    /// @dev
    /// UNDEFINED: market has not been created yet
    /// NOT_STARTED: market has been created but not opened yet
    /// OPEN: market is open for predictions
    /// PAUSED: market is paused !! by admin, only for emergencies
    /// CLOSED: market is closed, no more predictions can be made. Cannot cashout yet.
    /// FINISHED: market is finished, no more predictions can be made. Predictions can be cashed out.
    enum MarketState {
        UNDEFINED,
        NOT_STARTED,
        OPEN,
        PAUSED,
        CLOSED,
        FINISHED
    }

    function mint(address _better, uint256 _predictionId, uint256 _amount) external;

    function mintBatch(address _better, uint256[] calldata _predictionIds, uint256[] calldata _amounts) external;

    function burn(address _claimer, uint256 _id, uint256 _amount) external;

    function isOpen() external view returns (bool);

    function isFinished() external view returns (bool);

    function isClosed() external view returns (bool);

    function isNotStarted() external view returns (bool);

    function isUndefined() external view returns (bool);

    function isPaused() external view returns (bool);

    function open() external;

    function unpause() external;

    function pause() external;

    /// @notice Indefinitely finalizes a Prediction Market with the given winning prediction.
    /// @dev Caller is expected to be an authorized multisig or oracle (single source of truth)
    function submitResult(uint256 _winningPrediction) external;

    function isWinner(uint256 _predictionId) external view returns (bool);

    function setOracle(address _oracleAddress) external;

    function setEscrow(address _escrowAddress) external;
}
