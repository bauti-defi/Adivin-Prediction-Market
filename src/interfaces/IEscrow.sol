// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IEscrow {

    function buy(uint256 id, uint256 amount) external;


    function cashout(uint256 id) external;

}