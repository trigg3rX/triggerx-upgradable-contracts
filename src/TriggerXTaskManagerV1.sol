// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {BLSSignatureChecker, IRegistryCoordinator} from "@eigenlayer-middleware/BLSSignatureChecker.sol";
import "./ITriggerXTaskManagerV1.sol";
import {TriggerXServiceManagerV1} from "./TriggerXServiceManagerV1.sol";

contract TriggerXTaskManagerV1 is Initializable, OwnableUpgradeable, ITriggerXTaskManagerV1 {
    using BN254 for BN254.G1Point;

    BLSSignatureChecker public signatureChecker;
    uint32 public taskResponseWindowBlock;
    uint32 public constant TASK_CHALLENGE_WINDOW_BLOCK = 100;
    uint256 internal constant _THRESHOLD_DENOMINATOR = 100;

    uint32 public latestTaskNum;
    mapping(uint32 => bytes32) public allTaskHashes;
    mapping(uint32 => bytes32) public allTaskResponses;
    mapping(uint32 => bool) public taskSuccesfullyChallenged;

    address public aggregator;

    TriggerXServiceManagerV1 public serviceManager;

    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Aggregator must be the caller");
        _;
    }

    modifier operatorNotBlacklisted(address operator) {
        require(!serviceManager.operatorBlacklist(operator), "Operator is blacklisted");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    // Initialize function to replace constructor
    function initialize(
        IRegistryCoordinator _registryCoordinator,
        uint32 _taskResponseWindowBlock,
        TriggerXServiceManagerV1 _serviceManager,
        address initialOwner,
        address _aggregator
    ) public initializer {
        __Ownable_init();
        
        // Create a new BLSSignatureChecker instance
        signatureChecker = new BLSSignatureChecker(_registryCoordinator);
        
        taskResponseWindowBlock = _taskResponseWindowBlock;
        serviceManager = _serviceManager;
        aggregator = _aggregator;

        transferOwnership(initialOwner);
    }

    function createNewTask(
        uint32 jobId,
        bytes calldata quorumNumbers
    ) external {
        Task memory newTask;
        newTask.jobId = jobId;
        newTask.taskCreatedBlock = uint32(block.number);
        newTask.quorumNumbers = quorumNumbers;

        allTaskHashes[latestTaskNum] = keccak256(abi.encode(newTask));
        emit NewTaskCreated(latestTaskNum, newTask);
        latestTaskNum = latestTaskNum + 1;
    }

    function _validateTask(
        Task calldata task,
        TaskResponse calldata taskResponse
    ) internal view {
        require(
            keccak256(abi.encode(task)) == allTaskHashes[taskResponse.referenceTaskIndex],
            "Task mismatch"
        );
        require(allTaskResponses[taskResponse.referenceTaskIndex] == bytes32(0), "Already responded");
        require(uint32(block.number) <= task.taskCreatedBlock + taskResponseWindowBlock, "Response too late");
    }

    function _checkQuorumThresholds(
        QuorumStakeTotals memory quorumStakeTotals,
        bytes calldata quorumNumbers,
        uint32 quorumThresholdPercentage
    ) internal pure {
        // Threshold checking logic here
    }

    function respondToTask(
        Task calldata task,
        TaskResponse calldata taskResponse,
        NonSignerStakesAndSignature memory nonSignerStakesAndSignature
    ) external onlyAggregator operatorNotBlacklisted(taskResponse.operator) {
        _validateTask(task, taskResponse);

        bytes32 message = keccak256(abi.encode(taskResponse));
        (
            QuorumStakeTotals memory quorumStakeTotals,
            bytes32 hashOfNonSigners
        ) = signatureChecker.checkSignatures(
                message,
                task.quorumNumbers,
                task.taskCreatedBlock,
                nonSignerStakesAndSignature
            );

        for (uint i = 0; i < task.quorumNumbers.length; i++) {
            require(
                quorumStakeTotals.signedStakeForQuorum[i] * _THRESHOLD_DENOMINATOR >=
                quorumStakeTotals.totalStakeForQuorum[i] * uint8(serviceManager.quorumThresholdPercentage()),
                "Threshold not met"
            );
        }

        TaskResponseMetadata memory taskResponseMetadata = TaskResponseMetadata(
            uint32(block.number),
            hashOfNonSigners
        );
        
        allTaskResponses[taskResponse.referenceTaskIndex] = keccak256(
            abi.encode(taskResponse, taskResponseMetadata)
        );

        emit TaskResponded(taskResponse, taskResponseMetadata);
    }

    function _setAggregator(address newAggregator) internal {
        address oldAggregator = aggregator;
        aggregator = newAggregator;
        emit AggregatorUpdated(oldAggregator, newAggregator);
    }

    function setAggregator(address newAggregator) external onlyOwner {
        _setAggregator(newAggregator);
    }
}