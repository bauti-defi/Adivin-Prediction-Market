// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @author bauti.eth
/// @notice IPredictionMarket is ERC1155 wrapper impementation
interface IPredictionMarket {
    error InvalidPredictionId(uint256 predictionId);

    /// @dev 
    /// UNDEFINED: market has not been created yet
    /// NOT_STARTED: market has been created but not opened yet
    /// OPEN: market is open for predictions
    /// PAUSED: market is paused, only for emergencies
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

    function mint(address account, uint256 predictionId, uint256 amount) external;

    function mintBatch(address to, uint256[] memory predictionIds, uint256[] memory amounts) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function isOpen() external view returns (bool);

    function closeMarket(uint256 winningPrediction) external;
}
