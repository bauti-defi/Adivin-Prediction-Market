// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin-contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin-contracts/access/AccessControl.sol";
import "@src/interfaces/IPredictionMarket.sol";

contract PredictionMarket is IPredictionMarket, ERC1155, AccessControl, ERC1155Supply {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    MarketState public state;

    /// @dev 0 is invalid. Count starts at 1.
    uint256 public immutable optionCount;

    /// @dev 0 means no winner yet.
    uint256 public winningPrediction;
    uint256 public immutable expiration;

    /// TODO: Add correct media URI
    constructor(uint256 _optionCount, uint256 _expiration) ERC1155("https://localhost:3000") {
        require(_optionCount >= 2, "PredictionMarket: there must be at least two options");
        require(_expiration > block.timestamp, "PredictionMarket: expiration must be in the future");

        // set admin role to EOA
        _setupRole(ADMIN_ROLE, tx.origin);

        // Set admin for escrow role
        _setRoleAdmin(ESCROW_ROLE, ADMIN_ROLE);

        // set Admin for oracle role
        _setRoleAdmin(ORACLE_ROLE, ADMIN_ROLE);

        optionCount = _optionCount;
        expiration = _expiration;
        state = MarketState.NOT_STARTED;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ MODIFIERS ~~~~~~~~~~~~~~~~~~~~~~

    modifier validPrediction(uint256 predictionId) {
        _validPrediction(predictionId);
        _;
    }

    modifier whenNotStarted() {
        require(this.isNotStarted(), "PredictionMarket: market has already started");
        _;
    }

    modifier whenOpen() {
        require(this.isOpen(), "PredictionMarket: not open");
        _;
    }

    modifier whenPaused() {
        require(this.isPaused(), "PredictionMarket: not paused");
        _;
    }

    modifier whenClosed() {
        require(this.isClosed(), "PredictionMarket: not closed");
        _;
    }

    modifier whenFinished() {
        require(this.isFinished(), "PredictionMarket: not finished");
        _;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ TOKEN LIFECYCLE ~~~~~~~~~~~~~~~~~~~~~~

    function burn(address _claimer, uint256 _id, uint256 _amount)
        external
        override
        whenFinished
        validPrediction(_id)
        onlyRole(ESCROW_ROLE)
    {
        _burn(_claimer, _id, _amount);
    }

    function mint(address _better, uint256 _predictionId, uint256 _amount)
        external
        override
        whenOpen
        validPrediction(_predictionId)
        onlyRole(ESCROW_ROLE)
    {
        _mint(_better, _predictionId, _amount, "");
    }

    function mintBatch(address _better, uint256[] calldata _predictionIds, uint256[] calldata _amounts)
        external
        override
        whenOpen
        onlyRole(ESCROW_ROLE)
    {
        for (uint256 i = 0; i < _predictionIds.length; i++) {
            _validPrediction(_predictionIds[i]);
        }

        _mintBatch(_better, _predictionIds, _amounts, "");
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ MARKET STATE SETTERS ~~~~~~~~~~~~~~~~~~~~~~

    function open() external whenNotStarted onlyRole(DEFAULT_ADMIN_ROLE) {
        state = MarketState.OPEN;
    }

    function unpause() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        state = MarketState.OPEN;
    }

    function pause() external whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {
        state = MarketState.PAUSED;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ MARKET STATE GETTERS ~~~~~~~~~~~~~~~~~~~~~~

    function isUndefined() external view returns (bool) {
        return state == MarketState.UNDEFINED;
    }

    function isNotStarted() external view override returns (bool) {
        return state == MarketState.NOT_STARTED;
    }

    function isClosed() external view override returns (bool) {
        return state == MarketState.CLOSED || expiration >= block.timestamp;
    }

    function isOpen() external view override returns (bool) {
        return state == MarketState.OPEN;
    }

    function isFinished() external view override returns (bool) {
        return state == MarketState.FINISHED && winningPrediction != 0;
    }

    function isPaused() external view override returns (bool) {
        return state == MarketState.PAUSED;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ MARKET LIFECYCLE ~~~~~~~~~~~~~~~~~~~~~~

    function submitResult(uint256 _winningPrediction)
        external
        override
        whenClosed
        onlyRole(ORACLE_ROLE)
        validPrediction(_winningPrediction)
    {
        require(winningPrediction == 0, "PredictionMarket: winner already submitted");

        winningPrediction = _winningPrediction;
        state = MarketState.FINISHED;
    }

    /// ! Can force close regardless of expiration
    function closeBetting() external override whenOpen onlyRole(ORACLE_ROLE) {
        state = MarketState.CLOSED;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ NATIVE ERC1155 METHODS ~~~~~~~~~~~~~~~~~~~~~~

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

    /// ~~~~~~~~~~~~~~~~~~~~~~ HELPERS ~~~~~~~~~~~~~~~~~~~~~~

    function _validPrediction(uint256 predictionId) private view {
        if (predictionId > optionCount || predictionId == 0) revert InvalidPredictionId(predictionId);
    }

    function isWinner(uint256 _predictionId) external view validPrediction(_predictionId) returns (bool) {
        return winningPrediction == _predictionId;
    }
}
