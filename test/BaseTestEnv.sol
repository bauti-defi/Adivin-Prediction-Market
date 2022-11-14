// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

import "@test/utils/E20.sol";

import "@src/Factory.sol";

abstract contract BaseTestEnv is Test {
    address public admin;
    address public oracle;
    E20 public paymentToken;
    Factory public factory;

    function setUp() public virtual {
        console2.log("Created deployer address");
        admin = makeAddr("Admin");

        console2.log("Created oracle address");
        oracle = makeAddr("Oracle");

        console2.log("Created ERC20 payment token reference");
        paymentToken = new E20();

        vm.prank(admin, admin);
        console2.log("Created factory");
        factory = new Factory();
    }
}
