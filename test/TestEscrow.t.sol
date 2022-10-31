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

    function testCantMintMoreThanAllowedTokenSupplyCap() public openMarket {
        // 10 more than allowed cap
        uint256 amountToBuy = market.individualTokenSupplyCap() + 10;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        vm.expectRevert(abi.encodeWithSelector(IPredictionMarket.MaximumSupplyReached.selector, 1));
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

    function testSetProtocolFee(uint256 fee) public {
        vm.assume(fee < 100);

        vm.startPrank(admin, admin);
        escrow.setProtocolFee(fee);
        vm.stopPrank();

        assertEq(escrow.protocolFee(), fee);
    }

    function testOnlyAdminCanSetProtocolFee(address attacker) public {
        vm.assume(attacker != admin);

        vm.startPrank(attacker, attacker);
        vm.expectRevert(bytes("Escrow: only admin can call this function"));
        escrow.setProtocolFee(1);
        vm.stopPrank();
    }

    function testCantSetInvalidProtocolFee(uint256 fee) public {
        vm.assume(fee >= 100);

        vm.startPrank(admin, admin);
        vm.expectRevert(abi.encodeWithSelector(IEscrow.InvalidProtocolFee.selector, fee));
        escrow.setProtocolFee(fee);
        vm.stopPrank();
    }

    function testSetRevShareParticipants() public {
        address[] memory participants = new address[](2);
        participants[0] = vm.addr(1000);
        participants[1] = vm.addr(1001);

        uint256[] memory partitions = new uint256[](2);
        partitions[0] = 40;
        partitions[1] = 60;

        vm.startPrank(admin, admin);
        escrow.setRevShareRecipients(participants, partitions);
        vm.stopPrank();

        assertEq(escrow.revShareRecipients(0), participants[0]);
        assertEq(escrow.revShareRecipients(1), participants[1]);
        assertEq(escrow.revSharePartitions(0), partitions[0]);
        assertEq(escrow.revSharePartitions(1), partitions[1]);
    }

    function testOnlyAdminCanSetRevShareParticipants(address attacker) public {
        vm.assume(attacker != admin);

        address[] memory participants = new address[](2);
        participants[0] = vm.addr(1000);
        participants[1] = vm.addr(1001);

        uint256[] memory partitions = new uint256[](2);
        partitions[0] = 40;
        partitions[1] = 60;

        vm.startPrank(attacker, attacker);
        vm.expectRevert(bytes("Escrow: only admin can call this function"));
        escrow.setRevShareRecipients(participants, partitions);
        vm.stopPrank();
    }

    function testCantSetRevSharesToInvalidSum(uint256 sum, uint8 partitionCount) public {
        vm.assume(sum != 100);
        vm.assume(partitionCount > 0);
        vm.assume(sum / partitionCount > 0);

        address[] memory recipients = new address[](partitionCount);
        uint256[] memory partitions = new uint256[](partitionCount);

        for (uint8 i = 0; i < partitions.length; i++) {
            recipients[i] = vm.addr(1000 + i);
            partitions[i] = sum / uint256(partitionCount);
        }

        vm.startPrank(admin, admin);
        vm.expectRevert(IEscrow.InvalidRevShareSum.selector);
        escrow.setRevShareRecipients(recipients, partitions);
        vm.stopPrank();
    }

    function testCantSetRevSharesOfInvalidLength() public {
        address[] memory recipients = new address[](2);
        recipients[0] = vm.addr(1000);
        recipients[1] = vm.addr(1001);

        uint256[] memory partitions = new uint256[](1);
        partitions[0] = 100;

        vm.startPrank(admin, admin);
        vm.expectRevert(bytes("Escrow: recipients and shares arrays must be the same length"));
        escrow.setRevShareRecipients(recipients, partitions);
        vm.stopPrank();
    }

    function testCantRevShareOfZero() public {
        address[] memory recipients = new address[](1);
        uint256[] memory partitions = new uint256[](1);

        vm.startPrank(admin, admin);
        vm.expectRevert(bytes("Escrow: rev shares must be greater than 0"));
        escrow.setRevShareRecipients(recipients, partitions);
        vm.stopPrank();
    }
}
