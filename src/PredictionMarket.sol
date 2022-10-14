// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin-contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin-contracts/access/AccessControl.sol";
import "@src/interfaces/IPredictionMarket.sol";

contract PredictionMarket is IPredictionMarket, ERC1155, AccessControl, ERC1155Supply {
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");

    MarketState public state;

    // from 0 to optionCount - 1
    uint256 public immutable optionCount;
    uint256 public winningPrediction;

    modifier validPrediction(uint256 predictionId) {
        _validPrediction(predictionId);
        _;
    }

    modifier whenOpen() {
        require(state == MarketState.OPEN, "PredictionMarket: not open");
        _;
    }

    modifier whenPaused() {
        require(state == MarketState.PAUSED, "PredictionMarket: not paused");
        _;
    }

    constructor(uint256 _optionCount) ERC1155("https://localhost:3000") {
        require(_optionCount > 0, "PredictionMarket: optionCount must be > 0");
        // set EOA as admin
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        optionCount = _optionCount;
        state = MarketState.NOT_STARTED;
    }

    function mint(address account, uint256 predictionId, uint256 amount)
        external
        override
        onlyRole(ESCROW_ROLE)
        validPrediction(predictionId)
        whenOpen
    {
        _mint(account, predictionId, amount, "");
    }

    function mintBatch(address to, uint256[] memory predictionIds, uint256[] memory amounts)
        external
        override
        onlyRole(ESCROW_ROLE)
        whenOpen
    {
        for (uint256 i = 0; i < predictionIds.length; i++) {
            _validPrediction(predictionIds[i]);
        }

        _mintBatch(to, predictionIds, amounts, "");
    }

    function isStarted() external view returns (bool) {
        return state != MarketState.NOT_STARTED && state != MarketState.UNDEFINED;
    }

    function open() external {
        state = MarketState.OPEN;
    }

    function isOpen() external view override returns (bool) {
        return state == MarketState.OPEN;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenOpen {
        state = MarketState.PAUSED;
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        state = MarketState.OPEN;
    }

    function closeMarket(uint256 _winningPrediction)
        external
        override
        onlyRole(ESCROW_ROLE)
        validPrediction(_winningPrediction)
        whenOpen
    {
        winningPrediction = _winningPrediction;
        state = MarketState.CLOSED;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _validPrediction(uint256 predictionId) private view {
        if (predictionId >= optionCount) revert InvalidPredictionId(predictionId);
    }
}
