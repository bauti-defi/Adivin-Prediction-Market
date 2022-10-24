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

abstract contract BaseMarketTest is BaseTestEnv {
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

    function dealPaymentToken(address _user, uint256 _amount) internal returns (uint256) {
        uint256 scaledAmount = _amount * 10 ** paymentToken.decimals();
        paymentToken.mint(_user, scaledAmount);
        return scaledAmount;
    }

    function setUp() public virtual override {
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
}
