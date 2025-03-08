// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 /**
   * @title ContractName
   * @dev ContractDescription
   * @custom:dev-run-script scripts/deploy_with_ethers.ts
   */
contract MultiSignerSafe {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 noOfConfirmations;
    }

    event SafeInitialized(address[] owners, uint256 threshold);
    event TransactionProposed(
        uint256 indexed transactionId,
        address indexed owner,
        address destination,
        uint256 value,
        bytes data
    );
    event TransactionConfirmed(
        uint256 indexed transactionId,
        address indexed owner
    );
    event TransactionExecuted(
        uint256 indexed transactionId,
        address indexed owner
    );
    event AddOwnerInitiated(address owner);
    event RemoveOwnerInitiated(address owner);
    event ChangeThresholdInitiated(uint256 newThreshold);
    event OwnerAdded(address owner);
    event OwnerRemoved(address owner);
    event ThresholdChanged(uint256 newThreshold);

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "At least one owner is required");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

        owners = _owners;
        threshold = _threshold;

        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }

        emit SafeInitialized(_owners, _threshold);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owners can call this function");
        _;
    }

    function submitTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) public onlyOwner {
        transactions[transactionCount] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            noOfConfirmations: 0
        });

        confirmations[transactionCount][msg.sender] = true; // Auto confirm proposer
        transactions[transactionCount].noOfConfirmations++;

        emit TransactionProposed(transactionCount, msg.sender, destination, value, data);
        emit TransactionConfirmed(transactionCount, msg.sender);

        transactionCount++;
    }

    function confirmTransaction(uint256 transactionId) public onlyOwner {
        require(
            transactions[transactionId].destination != address(0),
            "Transaction does not exist"
        );
        require(
            !confirmations[transactionId][msg.sender],
            "Transaction already confirmed by this owner"
        );

        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].noOfConfirmations++;
        emit TransactionConfirmed(transactionId, msg.sender);
    }

    function executeTransaction(uint256 transactionId) public onlyOwner {
        Transaction storage transaction = transactions[transactionId];
        require(transaction.destination != address(0), "Transaction does not exist");
        require(!transaction.executed, "Transaction already executed");
        require(
            transaction.noOfConfirmations >= threshold,
            "Not enough confirmations"
        );

        (bool success, ) = transaction.destination.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction execution failed");

        transaction.executed = true;
        emit TransactionExecuted(transactionId, msg.sender);
    }

    // Optional advanced functions
    function addOwner(address owner) public onlyOwner {
        emit AddOwnerInitiated(owner);
    }

    function removeOwner(address owner) public onlyOwner {
        emit RemoveOwnerInitiated(owner);
    }

    function changeThreshold(uint256 newThreshold) public onlyOwner {
        emit ChangeThresholdInitiated(newThreshold);
    }

    // View functions
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function getTransaction(uint256 transactionId)
        public
        view
        returns (
            address destination,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 noOfconfirmations
        )
    {
        Transaction storage transaction = transactions[transactionId];
        return (
            transaction.destination,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.noOfConfirmations
        );
    }

    
}