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

contract TestRevShare is BaseMarketTest {
    modifier checkRevShareInvariants() {
        _;
        assertTrue(Invariants.totalEscrowedEqTokenBalance(escrow));
        assertTrue(Invariants.totalTokenSupplyIsLessThanAllowedSupplyCap(market));

        // token supply = total paid + total fee + total deposited
    }

    address[] revShareRecipients;
    uint256[] revSharePartitions;

    function setUp() public override {
        super.setUp();

        console2.log("Opening market");
        vm.prank(admin, admin);
        market.open();

        revShareRecipients = new address[](2);
        revShareRecipients[0] = vm.addr(100);
        revShareRecipients[1] = vm.addr(101);

        revSharePartitions = new uint256[](2);
        revSharePartitions[0] = 50;
        revSharePartitions[1] = 50;
    }

    function testBasicRevSharePayout() public checkRevShareInvariants {
        uint256 fee = 1;
        vm.startPrank(admin);
        escrow.setProtocolFee(fee);

        escrow.setRevShareRecipients(revShareRecipients, revSharePartitions);
        vm.stopPrank();

        uint256 amountToBuy = 100;

        // random buyer
        address buyer = vm.addr(50);
        uint256 amountToPay = dealPaymentToken(buyer, amountToBuy);

        vm.startPrank(buyer);
        paymentToken.approve(address(escrow), amountToPay);

        escrow.buy(1, amountToBuy);
        vm.stopPrank();

        vm.prank(admin);
        escrow.payoutFees();

        // done on paper
        assertEq(paymentToken.balanceOf(revShareRecipients[0]), 500000);
        assertEq(paymentToken.balanceOf(revShareRecipients[1]), 500000);
    }

    function testRevShare(uint8 fee, uint256 amountToBuy) public checkRevShareInvariants {
        vm.assume(fee < 100);
        vm.assume(fee > 0);
        vm.assume(amountToBuy > 0);
        vm.assume(amountToBuy < market.individualTokenSupplyCap());

        vm.startPrank(admin);
        escrow.setProtocolFee(fee);
        escrow.setRevShareRecipients(revShareRecipients, revSharePartitions);

        vm.stopPrank();

        // random buyer
        address buyer = vm.addr(50);

        uint256 amountToPay = dealPaymentToken(buyer, amountToBuy);

        vm.startPrank(buyer);
        paymentToken.approve(address(escrow), amountToPay);
        escrow.buy(1, amountToBuy);
        vm.stopPrank();

        vm.prank(revShareRecipients[0]);
        escrow.payoutFees();

        // divide by 100 twice since boh fee and partition are in %
        assertEq(paymentToken.balanceOf(revShareRecipients[0]), amountToPay * fee * revSharePartitions[0] / 100 / 100);
        assertEq(paymentToken.balanceOf(revShareRecipients[1]), amountToPay * fee * revSharePartitions[1] / 100 / 100);
    }
}
