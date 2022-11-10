// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

import "@src/Escrow.sol";
import "@src/PredictionMarket.sol";
import "@src/interfaces/IFactory.sol";

import "@test/BaseTestEnv.sol";

contract TestFactory is BaseTestEnv {
    PredictionMarket public market;
    Escrow public escrow;

    function setUp() public override {
        super.setUp();
    }

    function testCreateMarket() public {
        console2.log("Creating market");

        uint256 optionCount = 4;
        uint256 marketExpiration = block.timestamp + 1000;
        uint256 individualTokenSupplyCap = 100;

        vm.prank(admin, admin);
        factory.createMarket(
            "Test name",
            "Test description",
            "localhost:3000",
            optionCount,
            marketExpiration,
            individualTokenSupplyCap,
            address(paymentToken)
        );
    }
}
