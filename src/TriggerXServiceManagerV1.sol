// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// Remove this since ServiceManagerBase might already include ownership functionality
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; 
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@eigenlayer-middleware/ServiceManagerBase.sol";
import "./ITriggerXTaskManagerV1.sol";

// Remove OwnableUpgradeable from inheritance since ServiceManagerBase likely handles ownership
contract TriggerXServiceManagerV1 is Initializable, ServiceManagerBase {
    using EnumerableSet for EnumerableSet.AddressSet;

    ITriggerXTaskManagerV1 public triggerXTaskManager;
    EnumerableSet.AddressSet private _operators;
    mapping(address => bool) public operatorBlacklist;
    uint8 public quorumThresholdPercentage;

    event OperatorAdded(address indexed operator);
    event OperatorBlacklistStatusChanged(address indexed operator, bool blacklisted);
    event QuorumThresholdPercentageChanged(uint8 newThresholdPercentage);

    modifier onlyValidOperator() {
        require(_operators.contains(msg.sender), "Only valid operator can call this function");
        _;
    }

    function initialize(
        IAVSDirectory __avsDirectory,
        IRegistryCoordinator __registryCoordinator,
        IStakeRegistry __stakeRegistry,
        ITriggerXTaskManagerV1 __triggerXTaskManager,
        address initialOwner
    ) public initializer {
        __ServiceManagerBase_init(__avsDirectory, __registryCoordinator, __stakeRegistry);
        // Remove __Ownable_init() since ServiceManagerBase should handle ownership
        triggerXTaskManager = __triggerXTaskManager;
        // Use the ownership transfer method from ServiceManagerBase if available
        transferOwnership(initialOwner);
    }

    // Rest of your contract remains the same
    function registerOperatorToAVS(
        address operator,
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature
    ) public override onlyRegistryCoordinator {
        _avsDirectory.registerOperatorToAVS(operator, operatorSignature);
        _operators.add(operator);
        emit OperatorAdded(operator);
    }

    function whitelistOperator(address operator) external onlyOwner {
        require(operator != address(0), "Operator address cannot be zero");
        operatorBlacklist[operator] = false;
        emit OperatorBlacklistStatusChanged(operator, false);
    }

    function blacklistOperator(address operator) external onlyOwner {
        require(operator != address(0), "Operator address cannot be zero");
        operatorBlacklist[operator] = true;
        emit OperatorBlacklistStatusChanged(operator, true);
    }

    function isOperatorBlacklisted(address operator) external view returns (bool) {
        return operatorBlacklist[operator];
    }

    function updateQuorumThresholdPercentage(uint8 thresholdPercentage) external onlyOwner {
        require(thresholdPercentage <= 100, "Threshold percentage cannot be greater than 100");
        quorumThresholdPercentage = thresholdPercentage;
        emit QuorumThresholdPercentageChanged(thresholdPercentage);
    }
}