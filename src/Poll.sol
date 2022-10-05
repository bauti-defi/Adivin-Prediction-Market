// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin-contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin-contracts/access/AccessControl.sol";

contract Poll is ERC1155, AccessControl, ERC1155Supply {

    error InvalidPollOption(uint256 optionId);

    enum PollState {
        UNDEFINED,
        OPEN,
        PAUSED,
        CLOSED
    }

    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");

    PollState public state;

    // from 0 to optionCount - 1
    uint256 public immutable optionCount;
    uint256 public winner;
    
    modifier validOption(uint256 optionId) {
        _validOption(optionId);
        _;
    }

    modifier whenOpen() {
        require(state == PollState.OPEN, "Poll: not open");
        _;
    }

    modifier whenPaused() {
        require(state == PollState.PAUSED, "Poll: not paused");
        _;
    }

    constructor(uint256 _optionCount) ERC1155("https://localhost:3000") {
        require(_optionCount > 0, "Poll: optionCount must be > 0");
        // set EOA as admin
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        optionCount = _optionCount;
        state = PollState.OPEN;
    }

    function mint(address account, uint256 option, uint256 amount, bytes memory data) 
        external 
        onlyRole(ESCROW_ROLE) validOption(option) whenOpen() {
        _mint(account, option, amount, data);
    }

    function mintBatch(address to, uint256[] memory options, uint256[] memory amounts, bytes memory data)
        external
        onlyRole(ESCROW_ROLE) whenOpen()
    {
        for(uint256 i = 0; i < options.length; i++) {
            _validOption(options[i]);
        }

        _mintBatch(to, options, amounts, data);
    }

    function isOpen() external view returns (bool) {
        return state == PollState.OPEN;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenOpen() {
        state = PollState.PAUSED;
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused() {
        state = PollState.OPEN;
    }

    function closePoll(uint256 winningOption) external onlyRole(ESCROW_ROLE) validOption(winningOption) whenOpen() {
        winner = winningOption;
        state = PollState.CLOSED;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _validOption(uint256 optionId) private view {
        if(optionId >= optionCount) revert InvalidPollOption(optionId);
    }
    
}