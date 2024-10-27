// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {TriggerXJobManagerV1} from "../src/TriggerXJobManagerV1.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UpgradeTriggerXJobManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        TriggerXJobManagerV1 newImplementation = new TriggerXJobManagerV1();

        // Cast the proxy to UUPSUpgradeable and call upgradeTo
        UUPSUpgradeable(proxyAddress).upgradeTo(address(newImplementation));

        vm.stopBroadcast();

        console.log("Upgraded proxy at", proxyAddress);
        console.log("New implementation deployed to:", address(newImplementation));
    }
}