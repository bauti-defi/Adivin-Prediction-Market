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

    function testMultiBuy(uint8 buyerCount) public checkInvariants {
        uint256 amountToBuy = 100;

        for (uint256 i = 100; i < 100 + uint256(buyerCount); i++) {
            address buyer = vm.addr(i);
            uint256 amountToPay = dealPaymentToken(buyer, amountToBuy);

            vm.startPrank(buyer, buyer);
            paymentToken.approve(address(escrow), amountToPay);

            escrow.buy(1, amountToBuy);
            vm.stopPrank();
            assertEq(market.balanceOf(buyer, 1), amountToBuy);
            assertEq(paymentToken.balanceOf(address(escrow)), amountToPay * (i - 99));
        }
    }

    function testSimpleMultiCashout(uint8 buyerCount) public checkInvariants {
        uint256 amountToBuy = 100;

        for (uint256 i = 100; i < 100 + uint256(buyerCount); i++) {
            address buyer = vm.addr(i);
            uint256 amountToPay = dealPaymentToken(buyer, amountToBuy);

            vm.startPrank(buyer, buyer);
            paymentToken.approve(address(escrow), amountToPay);

            escrow.buy(1, amountToBuy);
            vm.stopPrank();
        }

        // skip forward so market expires
        skip(DURATION * 2);

        vm.prank(oracle, oracle);
        market.submitResult(1);

        for (uint256 i = 100; i < 100 + uint256(buyerCount); i++) {
            address buyer = vm.addr(i);

            vm.startPrank(buyer, buyer);
            escrow.cashout(1);
            vm.stopPrank();
        }

        assertEq(paymentToken.balanceOf(address(escrow)), 0);
        assertEq(market.totalSupply(1), 0);
    }

    function testComplexMultiCashout(uint8 buyerCount) public checkInvariants {
        uint256 amountToBuy = 100;

        for (uint256 i = 100; i < 100 + uint256(buyerCount); i++) {
            address buyer = vm.addr(i);
            uint256 amountToPay = dealPaymentToken(buyer, amountToBuy);

            vm.startPrank(buyer, buyer);
            paymentToken.approve(address(escrow), amountToPay);

            // if even, buy token 1, else buy token 2
            if (i % 2 == 0) {
                escrow.buy(1, amountToBuy);
            } else {
                escrow.buy(2, amountToBuy);
            }
            vm.stopPrank();
        }

        // skip forward so market expires
        skip(DURATION * 2);

        vm.prank(oracle, oracle);
        market.submitResult(1);

        for (uint256 i = 100; i < 100 + uint256(buyerCount); i++) {
            address buyer = vm.addr(i);

            vm.startPrank(buyer, buyer);
            if (i % 2 == 0) {
                escrow.cashout(1);
            }
            vm.stopPrank();
        }
    }
}
