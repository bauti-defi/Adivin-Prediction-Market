// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "@src/Escrow.sol";
import "@src/PredictionMarket.sol";
import "@test/utils/E20.sol";

contract SDK is Script {
    address constant ESCROW = 0x07cD05272fb4D7D4aA768e212CDD545E8bFCb773;
    address constant MARKET = 0x13286455a0D417F650e10fcC59Eb0754fbD6037A;

    function setEscrowRole() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        PredictionMarket market = PredictionMarket(MARKET);

        market.setEscrow(ESCROW);

        vm.stopBroadcast();
    }

    function bet() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        Escrow escrow = Escrow(ESCROW);

        E20 paymentToken = E20(0x6932b1073CdBd6dc6F09bf118E004E93e8B890f0);
        paymentToken.approve(ESCROW, 1000 * 10 ** paymentToken.decimals());

        escrow.buy(1, 100);

        vm.stopBroadcast();
    }
}
