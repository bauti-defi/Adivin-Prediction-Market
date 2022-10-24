// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@test/BaseTestEnv.sol";
import "@src/Factory.sol";
import "@src/PredictionMarket.sol";
import "@src/interfaces/IPredictionMarket.sol";
import "@src/interfaces/IEscrow.sol";
import "@src/Escrow.sol";
import "@test/utils/E20.sol";
import "@test/utils/Invariants.sol";

contract TestFullMarketCycle is BaseTestEnv {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    uint256 public constant DURATION = 10 * 5;
    uint256 public constant OPTION_COUNT = 4;

    PredictionMarket public market;
    Escrow public escrow;
    address public user;

    modifier checkInvariants() {
        _;
        assertTrue(Invariants.totalEscrowedEqTokenBalance(escrow));
        if (!market.isFinished()) assertTrue(Invariants.circulatingTokenSupplyEqTotalPot(market, escrow));
    }

    function setUp() public override {
        super.setUp();

        // create market
        vm.startPrank(admin, admin);
        (address _marketAddress, address _escrowAddress) =
            factory.createMarket(OPTION_COUNT, block.timestamp + DURATION, address(paymentToken));
        market = PredictionMarket(_marketAddress);
        escrow = Escrow(_escrowAddress);

        market.setOracle(oracle);
        market.setEscrow(address(escrow));
        vm.stopPrank();

        user = makeAddr("User");
    }

    function dealPaymentToken(address _user, uint256 _amount) internal returns (uint256) {
        uint256 scaledAmount = _amount * 10 ** paymentToken.decimals();
        paymentToken.mint(_user, scaledAmount);
        return scaledAmount;
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

    function testBuy() public checkInvariants {
        vm.prank(admin, admin);
        market.open();

        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        escrow.buy(1, amountToBuy);
        vm.stopPrank();

        assertEq(paymentToken.balanceOf(address(escrow)), amountToPay);
        assertEq(market.balanceOf(user, 1), amountToBuy);
    }

    function testMultiBuy(uint8 buyerCount) public checkInvariants {
        vm.prank(admin, admin);
        market.open();

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

    function testCashout() public checkInvariants {
        vm.prank(admin, admin);
        market.open();

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

    function testSimpleMultiCashout(uint8 buyerCount) public checkInvariants {
        vm.prank(admin, admin);
        market.open();

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
        vm.prank(admin, admin);
        market.open();

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

    function testCantCashoutBadPrediction() public checkInvariants {
        uint256 WINNING_PREDICTION = 1;
        uint256 LOSING_PREDICTION = 2;
        vm.prank(admin, admin);
        market.open();

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

    function testCantCashoutPredictionNotHeldInWallet() public checkInvariants {
        vm.prank(admin, admin);
        market.open();

        // skip forward so market expires
        skip(DURATION * 2);

        vm.prank(oracle, oracle);
        market.submitResult(1);

        vm.startPrank(user, user);
        vm.expectRevert(abi.encodeWithSelector(IEscrow.InsufficientPredictionTokenBalance.selector, 1));
        escrow.cashout(1);
        vm.stopPrank();
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
}
