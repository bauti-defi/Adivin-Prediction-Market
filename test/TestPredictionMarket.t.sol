// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@test/BaseMarketTest.sol";

contract TestPredictionMarket is BaseMarketTest {
    function setUp() public override {
        super.setUp();
    }

    function testOnlyOracleCanSubmitResult(address attacker) public {
        vm.assume(attacker != oracle);

        vm.prank(admin, admin);
        market.open();

        // skip forward so market expires
        skip(DURATION * 2);

        vm.startPrank(attacker, attacker);
        vm.expectRevert();
        market.submitResult(1);
    }

    function testOnlyEscrowCanMint(address attacker) public {
        vm.assume(attacker != address(escrow));

        vm.prank(admin, admin);
        market.open();

        vm.startPrank(attacker, attacker);
        vm.expectRevert();
        market.mint(attacker, 1, 1);
    }

    function testOnlyEscrowCanBatchMint(address attacker) public {
        vm.assume(attacker != address(escrow));

        vm.prank(admin, admin);
        market.open();

        uint256[] memory ids = new uint256[](4);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        ids[3] = 4;

        vm.startPrank(attacker, attacker);
        vm.expectRevert();
        market.mintBatch(attacker, ids, ids);
    }

    function testOnlyEscrowCanBurn(address attacker) public {
        vm.assume(attacker != address(escrow));

        vm.prank(admin, admin);
        market.open();

        vm.startPrank(attacker, attacker);
        vm.expectRevert();
        market.burn(attacker, 1, 1);
    }
}
