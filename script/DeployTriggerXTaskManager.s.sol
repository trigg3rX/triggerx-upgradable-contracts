// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {TriggerXTaskManagerV1} from "../src/TriggerXTaskManagerV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployTriggerXTaskManager is Script {
    function run(
        address registryCoordinator,
        uint32 taskResponseWindowBlock,
        address serviceManager
    ) external returns (address proxyAddr, address implementation) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        TriggerXTaskManager taskManager = new TriggerXTaskManager(
            registryCoordinator,
            taskResponseWindowBlock,
            TriggerXServiceManager(serviceManager)
        );

        // Encode initialize function call
        bytes memory data = abi.encodeWithSelector(
            TriggerXTaskManager.initialize.selector,
            address(0x123), // pauserRegistry placeholder
            msg.sender,     // initial owner
            msg.sender      // aggregator
        );

        // Deploy proxy
        ERC1967Proxy proxyContract = new ERC1967Proxy(
            address(taskManager),
            data
        );

        vm.stopBroadcast();

        console.log("Proxy deployed to:", address(proxyContract));
        console.log("Implementation deployed to:", address(taskManager));

        return (address(proxyContract), address(taskManager));
    }
}
