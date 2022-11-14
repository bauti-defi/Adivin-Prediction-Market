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

        uint256 marketExpiration = block.timestamp + 1000;
        uint256 individualTokenSupplyCap = 100;

        // create color array
        bytes6[] memory tokenColors = new bytes6[](2);
        tokenColors[0] = 0x000000;
        tokenColors[1] = 0x000000;

        // create name array
        string[] memory tokenNames = new string[](2);
        tokenNames[0] = "Yes";
        tokenNames[1] = "No";

        vm.prank(admin, admin);
        factory.createMarket(
            IFactory.Parameters({
                _marketName: "Test Market",
                _description: "This is a test market",
                _mediaUri: "localhost:3000",
                _marketExpirationDate: marketExpiration,
                _marketResolveDate: marketExpiration - 500,
                _individualTokenSupplyCap: individualTokenSupplyCap,
                _individualTokenPrice: 1,
                _paymentToken: address(paymentToken),
                _tokenNames: tokenNames,
                _tokenColors: tokenColors,
                _tokenCost: 10,
                _categories: "Sports, Medicine"
            })
        );
    }
}
