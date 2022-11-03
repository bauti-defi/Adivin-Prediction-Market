// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "@src/Factory.sol";

contract FactoryDeployer is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy our factory contract
        Factory factory = new Factory();

        vm.stopBroadcast();
    }

}