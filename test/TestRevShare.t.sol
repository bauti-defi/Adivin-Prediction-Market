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
    }

    function testBasicRevSharePayout() public checkRevShareInvariants {
        uint256 fee = 1;
        vm.prank(admin, admin);
        escrow.setProtocolFee(fee);

        uint256 amountToBuy = 100;

        address buyer = vm.addr(100);
        uint256 amountToPay = dealPaymentToken(buyer, amountToBuy);

        vm.startPrank(buyer, buyer);
        paymentToken.approve(address(escrow), amountToPay);

        escrow.buy(1, amountToBuy);
        vm.stopPrank();
    }
}