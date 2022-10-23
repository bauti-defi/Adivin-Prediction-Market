// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

import "@src/Factory.sol";

abstract contract BaseTestEnv is Test {
    uint256 public constant predictionCount = 3;

    address public deployer;
    address public oracle;
    ERC20 public paymentToken;
    Factory public factory;

    function setUp() public virtual {
        console2.log("Created deployer address");
        deployer = makeAddr("Deployer");

        console2.log("Created oracle address");
        oracle = makeAddr("Oracle");

        console2.log("Created ERC20 payment token reference");
        paymentToken = ERC20(vm.addr(1));

        vm.prank(deployer, deployer);
        console2.log("Created factory");
        factory = new Factory();
    }
}
