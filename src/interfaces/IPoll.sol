// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPoll {

    error InvalidPollOption(uint256 optionId);


enum PollState {
        UNDEFINED,
        OPEN,
        PAUSED,
        CLOSED
}

    function mint(address account, uint256 option, uint256 amount, bytes memory data) external;

    function mintBatch(address to, uint256[] memory options, uint256[] memory amounts, bytes memory data) external;

    function isOpen() external view returns (bool);

    function closePoll(uint256 winningOption) external;

}
