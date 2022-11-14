// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin-contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin-contracts/access/AccessControl.sol";
import "@src/interfaces/IPredictionMarket.sol";

/// @author bauti.eth
contract PredictionMarket is IPredictionMarket, ERC1155, AccessControl, ERC1155Supply {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    MarketState public state;

    /// @dev 0 means no winner yet.
    uint256 public winningPrediction;

    uint256 public immutable expirationDate;
    uint256 public immutable resolveDate;
    uint256 public immutable individualTokenSupplyCap;
    string public name;
    string public description;
    string public categories;

    /// @dev indice 0 maps to option 1. indice 1 maps to option 2, etc.
    /// option 0 does not exist.
    TokenMetadata[] public tokenMetadata;

    /// TODO: extract all this metadata into IPFS

    constructor(
        string memory _name,
        string memory _description,
        string memory _mediaUri,
        uint256 _expirationDate,
        uint256 _resolveDate,
        uint256 _individualTokenSupplyCap,
        string[] memory _tokenNames,
        bytes6[] memory _tokenColors,
        string memory _categories
    ) ERC1155("") {
        require(_tokenColors.length >= 2, "PredictionMarket: there must be at least two options");
        require(_tokenColors.length == _tokenNames.length, "Factory: token colors and names must be the same length");
        require(_expirationDate > _resolveDate, "PredictionMarket: resolve date must be before expiration date");
        require(_expirationDate > block.timestamp, "PredictionMarket: expiration date must be in the future");

        // set admin role to EOA
        _setupRole(ADMIN_ROLE, tx.origin);

        // Set admin for escrow role
        _setRoleAdmin(ESCROW_ROLE, ADMIN_ROLE);

        // set Admin for oracle role
        _setRoleAdmin(ORACLE_ROLE, ADMIN_ROLE);

        for (uint256 i = 0; i < _tokenNames.length;) {
            tokenMetadata.push(IPredictionMarket.TokenMetadata({name: _tokenNames[i], color: _tokenColors[i]}));

            unchecked {
                // will never overflow
                ++i;
            }
        }

        expirationDate = _expirationDate;
        resolveDate = _resolveDate;
        categories = _categories;

        if (_individualTokenSupplyCap == 0) {
            _individualTokenSupplyCap = type(uint256).max;
        }

        individualTokenSupplyCap = _individualTokenSupplyCap;
        state = MarketState.OPEN;
        name = _name;
        description = _description;
        _setURI(_mediaUri);
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ MODIFIERS ~~~~~~~~~~~~~~~~~~~~~~

    modifier validPrediction(uint256 predictionId) {
        _checkIsValidPrediction(predictionId);
        _;
    }

    modifier whenNotStarted() {
        require(this.isNotStarted(), "PredictionMarket: market has already started");
        _;
    }

    modifier whenOpen() {
        if (!this.isOpen()) revert MarketNotOpen();
        _;
    }

    modifier whenPaused() {
        require(this.isPaused(), "PredictionMarket: not paused");
        _;
    }

    modifier whenClosed() {
        if (expirationDate > block.timestamp) revert MarketNotClosed();

        // switch flag if necesarry
        if (state != MarketState.CLOSED) state = MarketState.CLOSED;
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
        _checkMintDoesNotExceedMaxSupply(_predictionId, _amount);

        _mint(_better, _predictionId, _amount, "");
    }

    function mintBatch(address _better, uint256[] calldata _predictionIds, uint256[] calldata _amounts)
        external
        override
        whenOpen
        onlyRole(ESCROW_ROLE)
    {
        for (uint256 i = 0; i < _predictionIds.length; i++) {
            _checkIsValidPrediction(_predictionIds[i]);
            _checkMintDoesNotExceedMaxSupply(_predictionIds[i], _amounts[i]);
        }

        _mintBatch(_better, _predictionIds, _amounts, "");
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ MARKET STATE SETTERS ~~~~~~~~~~~~~~~~~~~~~~

    function open() external whenNotStarted onlyRole(ADMIN_ROLE) {
        state = MarketState.OPEN;
    }

    function unpause() external whenPaused onlyRole(ADMIN_ROLE) {
        state = MarketState.OPEN;
    }

    function pause() external whenOpen onlyRole(ADMIN_ROLE) {
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
        return state == MarketState.CLOSED || expirationDate <= block.timestamp;
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

        emit ResultSubmitted(_winningPrediction, block.timestamp);
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

    /// @notice this does not check that _tokenId is a valid predictionId
    function _checkMintDoesNotExceedMaxSupply(uint256 _tokenId, uint256 _amount) private view {
        if (this.totalSupply(_tokenId) + _amount > individualTokenSupplyCap) revert MaximumSupplyReached(_tokenId);
    }

    function _checkIsValidPrediction(uint256 predictionId) private view {
        if (predictionId > tokenMetadata.length || predictionId == 0) revert InvalidPredictionId(predictionId);
    }

    function isWinner(uint256 _predictionId) external view validPrediction(_predictionId) returns (bool) {
        return winningPrediction == _predictionId;
    }

    function setOracle(address _oracleAddress) public onlyRole(ADMIN_ROLE) {
        _setupRole(ORACLE_ROLE, _oracleAddress);
    }

    function setEscrow(address _escrowAddress) public onlyRole(ADMIN_ROLE) {
        _setupRole(ESCROW_ROLE, _escrowAddress);
    }
}
