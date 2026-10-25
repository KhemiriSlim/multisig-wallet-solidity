// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet{
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;
    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    event TransactionSubmit(uint256 indexed id, address indexed sender,address indexed to,uint256 value,bytes data);
    event ConfirmTransaction(address indexed _owner,uint256 indexed _id);
    event ExecuteTransaction(uint256 indexed _txId);
    event RevokeConfirmation(uint256 indexed _txId);
    constructor(address[] memory _owners,uint256 _required){
        require(_owners.length > 0 , "no Owners");
        require(_required > 0 && _required <= _owners.length,"check the required Owners number");
        for(uint256 i =0 ; i < _owners.length ; i++){
            address owner = _owners[i];
            require(owner != address(0),"check you address");
            require(!isOwner[owner] ,"owner already exists");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external  payable {}


    modifier onlyOwner{
        require(isOwner[msg.sender],"you are not Owner");
        _;
    }

    modifier txExists(uint256 _txId){
        require(_txId < transactions.length,"the transaction not exist");
        _;
    }

    modifier notExecuted(uint256 _txId){
        require(!transactions[_txId].executed,"the transaction executed");
        _;
    }

    modifier notConfirmed(uint256 _txId){
        require(!confirmed[_txId][msg.sender],"the transaction already confemid");
        _;
    }

    function submitTransaction(address _to,uint256 _value,bytes memory _data) public onlyOwner{
        uint256 transactionLength = transactions.length;
        transactions.push(Transaction(_to,_value,_data,false,0));
        emit TransactionSubmit(transactionLength,msg.sender,_to,_value,_data);
    }
    function confirmTransaction(uint256 _txId) public onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId){
        Transaction storage TransactionToConfirm = transactions[_txId];
        TransactionToConfirm.numConfirmations += 1;
        confirmed[_txId][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txId);
    }

    function executeTransaction(uint _txId) public onlyOwner txExists(_txId) notExecuted(_txId){
        Transaction storage TransactionToExecute = transactions[_txId];
        require(TransactionToExecute.numConfirmations >= required,"still need owners to execute");
        TransactionToExecute.executed = true;
        (bool callSuccess, ) = payable(TransactionToExecute.to).call{value : TransactionToExecute.value}(TransactionToExecute.data);
        require(callSuccess,"call failed");
        emit ExecuteTransaction(_txId);
    }

    function revokeConfirmation(uint256 _txId) public  onlyOwner txExists(_txId) notExecuted(_txId){
        require(confirmed[_txId][msg.sender],"you already dosn t confirm");
        Transaction storage theTansaction = transactions[_txId];
        theTansaction.numConfirmations -= 1;
        confirmed[_txId][msg.sender] = false;
        emit RevokeConfirmation(_txId);
    }
}