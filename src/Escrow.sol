// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IEscrow.sol";
import "@src/Poll.sol";
import "@src/interfaces/IPoll.sol";
import "@openzeppelin-contracts/access/AccessControl.sol";
import "@openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin-contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-contracts/security/ReentrancyGuard.sol";

contract Escrow is IEscrow, ERC1155Holder, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant POLL_STARTER_ROLE = keccak256("POLL_STARTER_ROLE");
    bytes32 public constant POLL_FINALIZER_ROLE = keccak256("POLL_FINALIZER_ROLE");

    uint256 public pollIdNonce;
    IERC20 public immutable paymentToken;
    mapping(uint256 => PollData) polls;

    constructor(address token) {
        // set EOA as admin
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        // set EOA as poll starter
        _setupRole(POLL_STARTER_ROLE, tx.origin);
        paymentToken = IERC20(token);
    }

    function startPoll(address poll) external override onlyRole(POLL_STARTER_ROLE) {
        Poll pollContract = Poll(poll);

        require(pollContract.isOpen(), "Escrow: poll must be open");

        polls[pollIdNonce++] = PollData({poll: pollContract, pot: 0});

        emit PollOpened(pollIdNonce - 1, poll);
    }

    function submitPollResult(uint256 pollId, uint256 winningId) external override onlyRole(POLL_FINALIZER_ROLE) {
        Poll pollContract = polls[pollId].poll;

        require(pollContract.state() != IPoll.PollState.UNDEFINED, "Escrow: Poll is undefined");

        // close poll and register the winning option
        pollContract.closePoll(winningId);

        emit PollEnded(pollId, winningId, address(pollContract));
    }

    function buy(uint256 pollId, uint256 pollOptionId, uint256 amount) external override nonReentrant {
        // transfer their stables into the escrow
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);

        // Get the poll
        PollData storage pollData = polls[pollId];

        // Check it is defined
        require(pollData.poll.state() != IPoll.PollState.UNDEFINED, "Escrow: Poll is undefined");

        // update pot
        pollData.pot += amount;

        // mint option tokens to the msg.sender
        pollData.poll.mint(msg.sender, pollOptionId, amount, "");

        // emit event
        emit PredictionMade(pollId, msg.sender, pollOptionId, amount, pollData.pot);
    }

    function cashout(uint256 pollId, uint256 optionId) external override nonReentrant {
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
