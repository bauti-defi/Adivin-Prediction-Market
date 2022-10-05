// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IEscrow {

    event PollEnded(uint256 indexed pollId, uint256 winningId, address pollAddress);
    event PollOpened(uint256 indexed pollId, address pollAddress);

    function buy(uint256 id, uint256 amount) external;

    // Users need to personally cashout
    function cashout(uint256 pollId, uint256 optionId) external;

    function startPoll(address poll) external;

    // should only be called by contracts (oracles) that have been approved by the owner
    // these contracts should be proxies that decode incoming data streams into (poll, winner) tupples
    // those tupples are the parameters below
    // ? could be a chainlink oracle or multisig
    function submitPollResult(uint256 pollId, uint256 winningId) external;

}