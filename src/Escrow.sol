// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IEscrow.sol";
import "@src/Poll.sol";
import "@src/interfaces/IPoll.sol";
import "@openzeppelin-contracts/access/AccessControl.sol";
import "@openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin-contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Escrow is IEscrow, ERC1155Holder, AccessControl {
    bytes32 public constant POLL_STARTER_ROLE = keccak256("POLL_STARTER_ROLE");
    bytes32 public constant POLL_FINALIZER_ROLE = keccak256("POLL_FINALIZER_ROLE");

    uint256 public pollIdNonce;
    address public immutable tokenAddress;
    mapping(uint256 => Poll) polls;

    constructor(address token) {
        // set EOA as admin
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        // set EOA as poll starter
        _setupRole(POLL_STARTER_ROLE, tx.origin);
        tokenAddress = token;
    }

    function startPoll(address poll) external override onlyRole(POLL_STARTER_ROLE) {
        Poll pollContract = Poll(poll);

        require(pollContract.isOpen(), "Escrow: poll must be open");

        polls[pollIdNonce++] = pollContract;

        emit PollOpened(pollIdNonce - 1, poll);
    }

    function submitPollResult(uint256 pollId, uint256 winningId) external override onlyRole(POLL_FINALIZER_ROLE) {
        Poll pollContract = polls[pollId];

        require(pollContract.state() != IPoll.PollState.UNDEFINED, "Escrow: does not exist");

        // close poll and register the winning option
        pollContract.closePoll(winningId);

        emit PollEnded(pollId, winningId, address(pollContract));
    }

    function buy(uint256 id, uint256 amount) external override {
        // transfer their stables to the escrow
        // update balance

        // mint option tokens to the msg.sender

        // emit event
    }

    function cashout(uint256 pollId, uint256 optionId) external override {
        // update token balance for escrow
        // receive option tokens from the msg.sender
        // send stables to the msg.sender
        // emit
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
