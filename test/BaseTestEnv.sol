// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

import "@src/Escrow.sol";
import "@src/PredictionMarket.sol";

abstract contract BaseTestEnv is Test {
    uint256 public constant predictionCount = 3;

    address public deployer;
    address public oracle;
    ERC20 public paymentToken;
    Escrow public escrow;
    PredictionMarket public predictionMarket;

    function setUp() public virtual {
        console2.log("Created deployer address");
        deployer = makeAddr("Deployer");

        console2.log("Created oracle address");
        oracle = makeAddr("Oracle");

        console2.log("Created ERC20 payment token reference");
        paymentToken = ERC20(vm.addr(1));

        vm.startPrank(deployer, deployer);
        console2.log("Created Escrow");
        escrow = new Escrow(address(paymentToken));
        vm.label(address(escrow), "Escrow");

        console2.log("Grant oracle MARKET_CLOSER_ROLE");
        escrow.grantRole(escrow.MARKET_CLOSER_ROLE(), oracle);

        console2.log("Created Prediction Market ERC1155");
        predictionMarket = new PredictionMarket(predictionCount);
        vm.label(address(predictionMarket), "Prediction Market");

        console2.log("Opened prediction market");
        escrow.openMarket(address(predictionMarket));
        vm.stopPrank();
    }
}
