// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {TriggerXServiceManagerV1} from "../src/TriggerXServiceManagerV1.sol";
import {TriggerXTaskManagerV1} from "../src/TriggerXTaskManagerV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployTriggerXServiceManager is Script {
    function run(
        address avsDirectory,
        address registryCoordinator,
        address stakeRegistry,
        address triggerXTaskManagerV1
    ) external returns (address proxyAddr, address implementation) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        TriggerXServiceManagerV1 serviceManager = new TriggerXServiceManagerV1(
            avsDirectory,
            registryCoordinator,
            stakeRegistry,
            TriggerXTaskManagerV1(triggerXTaskManagerV1)
        );

        // No initializer function needed here, as constructor is sufficient

        // Deploy proxy with no data (for non-initializable contracts)
        ERC1967Proxy proxyContract = new ERC1967Proxy(
            address(serviceManager),
            ""
        );

        vm.stopBroadcast();

        console.log("Proxy deployed to:", address(proxyContract));
        console.log("Implementation deployed to:", address(serviceManager));

        return (address(proxyContract), address(serviceManager));
    }
}
