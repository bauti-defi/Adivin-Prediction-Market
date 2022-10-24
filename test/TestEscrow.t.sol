// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@test/BaseMarketTest.sol";
import "@src/Factory.sol";
import "@src/PredictionMarket.sol";
import "@src/interfaces/IPredictionMarket.sol";
import "@src/interfaces/IEscrow.sol";
import "@src/Escrow.sol";
import "@test/utils/E20.sol";
import "@test/utils/Invariants.sol";

contract TestEscrow is BaseMarketTest {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    function setUp() public override {
        super.setUp();
    }

    function testCantCashoutTillFinalized() public {
        vm.startPrank(user, user);
        vm.expectRevert(bytes("Escrow: Market is not finished"));
        escrow.cashout(1);
        vm.stopPrank();
    }

    function testCantBuyIfMarketIsNotOpen() public {
        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        vm.expectRevert(IPredictionMarket.MarketNotOpen.selector);
        escrow.buy(1, amountToBuy);
        vm.stopPrank();
    }

    function testCantBuyIfMarketIsPaused() public openMarket pauseMarket {
        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        vm.expectRevert(IPredictionMarket.MarketNotOpen.selector);
        escrow.buy(1, amountToBuy);
        vm.stopPrank();
    }

    function testBuy() public openMarket pauseMarket unpauseMarket checkInvariants {
        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        escrow.buy(1, amountToBuy);
        vm.stopPrank();

        assertEq(paymentToken.balanceOf(address(escrow)), amountToPay);
        assertEq(market.balanceOf(user, 1), amountToBuy);
    }

    function testCantBuyInvalidPredictionOption(uint8 predictionId) public openMarket {
        vm.assume(predictionId > market.optionCount() || predictionId == 0);

        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        vm.expectRevert(abi.encodeWithSelector(IPredictionMarket.InvalidPredictionId.selector, predictionId));
        escrow.buy(predictionId, amountToBuy);
        vm.stopPrank();
    }

    function testCashout() public checkInvariants openMarket {
        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        escrow.buy(1, amountToBuy);
        vm.stopPrank();

        // skip forward so market expires
        skip(DURATION * 2);

        vm.prank(oracle, oracle);
        market.submitResult(1);

        vm.startPrank(user, user);

        // check burn event is emitted
        vm.expectEmit(true, false, false, false, address(market));
        emit TransferSingle(address(escrow), address(escrow), user, 1, amountToBuy);

        escrow.cashout(1);
        vm.stopPrank();

        assertEq(paymentToken.balanceOf(address(user)), amountToPay);
        assertEq(paymentToken.balanceOf(address(escrow)), 0);
        assertEq(market.balanceOf(user, 1), 0);
    }

    function testCantCashoutBadPrediction() public openMarket checkInvariants {
        uint256 WINNING_PREDICTION = 1;
        uint256 LOSING_PREDICTION = 2;

        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        escrow.buy(LOSING_PREDICTION, amountToBuy);
        vm.stopPrank();

        // skip forward so market expires
        skip(DURATION * 2);

        vm.prank(oracle, oracle);
        market.submitResult(WINNING_PREDICTION);

        vm.startPrank(user, user);
        vm.expectRevert(abi.encodeWithSelector(IEscrow.IncorrectPrediction.selector, LOSING_PREDICTION));
        escrow.cashout(LOSING_PREDICTION);
        vm.stopPrank();

        assertEq(paymentToken.balanceOf(address(user)), 0);
        assertEq(paymentToken.balanceOf(address(escrow)), amountToPay);
        assertEq(market.balanceOf(user, LOSING_PREDICTION), amountToBuy);
    }

    function testCantCashoutPredictionNotHeldInWallet() public openMarket checkInvariants {
        // skip forward so market expires
        skip(DURATION * 2);

        vm.prank(oracle, oracle);
        market.submitResult(1);

        vm.startPrank(user, user);
        vm.expectRevert(abi.encodeWithSelector(IEscrow.InsufficientPredictionTokenBalance.selector, 1));
        escrow.cashout(1);
        vm.stopPrank();
    }
}
