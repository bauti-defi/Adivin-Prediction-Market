// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

import "@src/Escrow.sol";
import "@src/PredictionMarket.sol";

import "@test/BaseTestEnv.sol";

contract TestEscrowLifeCycle is BaseTestEnv {
    function setUp() public override {
        super.setUp();
    }
}
