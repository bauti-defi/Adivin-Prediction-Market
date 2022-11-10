// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "@src/Factory.sol";
import "@test/utils/E20.sol";
import "@src/PredictionMarket.sol";

contract FactoryDeployer is Script {
    function deploy() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy our factory contract
        Factory factory = new Factory();

        vm.stopBroadcast();
    }

    function deployWithTestMarket() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        E20 paymentToken = new E20();
        // mint deployer 1000 tokens worth of erc20
        paymentToken.mint(vm.addr(deployerPrivateKey), 1000 * 10 ** paymentToken.decimals());

        // Deploy our factory contract
        Factory factory = new Factory();

        // create a market
        (address marketAddr, address escrowAdrr) = factory.createMarket({
            _marketName: "Test Market",
            _description: "This is a test market",
            _mediaUri: "localhost:3000",
            _predictionCount: 2,
            _marketExpirationDate: block.timestamp + 2 days,
            _marketResolveDate: block.timestamp + 1 days,
            _individualTokenSupplyCap: 100,
            _paymentToken: address(paymentToken)
        });

        PredictionMarket market = PredictionMarket(marketAddr);
        market.setEscrow(escrowAdrr);

        vm.stopBroadcast();
    }
}
