// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @author bauti.eth
/// @notice IPredictionMarket is ERC1155 wrapper impementation
interface IPredictionMarket {
    error InvalidPredictionId(uint256 predictionId);

    enum MarketState {
        UNDEFINED,
        NOT_STARTED,
        OPEN,
        PAUSED,
        CLOSED
    }

    function mint(address account, uint256 predictionId, uint256 amount) external;

    function mintBatch(address to, uint256[] memory predictionIds, uint256[] memory amounts) external;

    function isOpen() external view returns (bool);

    function closeMarket(uint256 winningPrediction) external;
}
