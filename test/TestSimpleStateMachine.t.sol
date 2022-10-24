// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@test/BaseMarketTest.sol";

contract TestSimpleStateMachine is BaseMarketTest {
    function setUp() public override {
        super.setUp();

        console2.log("Opening market");
        vm.prank(admin, admin);
        market.open();
    }

    function isEven(uint8 n) internal pure returns (bool) {
        return n % 2 == 0;
    }

    function testTrue(uint8[1000] memory steps) public {
        for (uint256 i = 0; i < steps.length; i++) {
            if (isEven(steps[i])) console2.logUint(uint256(steps[i]));

            assertTrue(true);
        }
    }
}
