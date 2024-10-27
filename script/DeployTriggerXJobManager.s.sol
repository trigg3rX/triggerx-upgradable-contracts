// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {TriggerXJobManagerV1} from "../src/TriggerXJobManagerV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployTriggerXJobManager is Script {
    function run() external returns (address proxyAddr, address implementation) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        TriggerXJobManagerV1 jobManager = new TriggerXJobManagerV1();
        
        // Encode initialize function call
        bytes memory data = abi.encodeWithSelector(TriggerXJobManagerV1.initialize.selector);
        
        // Deploy proxy
        ERC1967Proxy proxyContract = new ERC1967Proxy(
            address(jobManager),
            data
        );

        vm.stopBroadcast();

        console.log("Proxy deployed to:", address(proxyContract));
        console.log("Implementation deployed to:", address(jobManager));

        return (address(proxyContract), address(jobManager));
    }
}