// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@test/BaseTestEnv.sol";
import "@src/Factory.sol";
import "@src/PredictionMarket.sol";
import "@src/Escrow.sol";

contract TestFullMarketCycle is BaseTestEnv {
    uint256 public constant DURATION = 10 * 5;

    PredictionMarket public market;
    Escrow public escrow;
    address public user;

    function setUp() public override {
        super.setUp();

        // create market
        vm.startPrank(admin, admin);
        (address _marketAddress, address _escrowAddress) =
            factory.createMarket(4, block.timestamp + DURATION, address(paymentToken));
        market = PredictionMarket(_marketAddress);
        escrow = Escrow(_escrowAddress);
        vm.stopPrank();

        user = makeAddr("User");
    }

    function testCantCashoutTillFinalized() public {
        vm.startPrank(user, user);
        vm.expectRevert(bytes("Escrow: Market is not finished"));
        escrow.cashout(1);
        vm.stopPrank();
    }
}
