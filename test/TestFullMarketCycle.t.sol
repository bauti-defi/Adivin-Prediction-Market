// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "@test/BaseTestEnv.sol";
import "@src/Factory.sol";
import "@src/PredictionMarket.sol";
import "@src/interfaces/IPredictionMarket.sol";
import "@src/Escrow.sol";
import "@test/utils/E20.sol";
import "@test/utils/Invariants.sol";

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

    function testBuy() public {
        vm.prank(admin, admin);
        market.open();

        uint256 amountToBuy = 100;
        uint256 amountToPay = dealPaymentToken(user, amountToBuy);

        vm.startPrank(user, user);
        paymentToken.approve(address(escrow), amountToPay);

        escrow.buy(1, amountToBuy);
        vm.stopPrank();

        assertTrue(Invariants.totalEscrowedEqTokenBalance(escrow));
        assertTrue(Invariants.circulatingTokenSupplyEqTotalPot(market, escrow));
    }
}
