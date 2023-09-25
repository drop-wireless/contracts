// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./base.sol";

contract Escrow is usingERC20 {
    address public owner;
    mapping (string=>bool) allocOfUUID;
    mapping (string=>Hold) holdOfUUID;
    string[] UUIDs;

    constructor(address _tokenAddress) usingERC20(_tokenAddress) {
        owner = msg.sender;
    }
    struct Hold {
        address payer;
        uint paid;
        address[] payees;
        uint[] shares;
    }

// contract management
    function transferOwnership(address newOnwer)
        external
        onlyOwner {
        owner = newOnwer;
    }
    function withdraw(uint _amount)
        external
        onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "Not enough balance in the contract");
        require(token.transfer(msg.sender, _amount), "Unable to transfer token to the owner account");
    }

// look up hold
    function getHoldOf(string calldata _uuid)
        external
        view
        UUIDExists(_uuid)
        returns (Hold memory) {
        return holdOfUUID[_uuid];
    }

// hold, return or pay shares 
    function holdPayment(string calldata _uuid, uint _totalAmount, address[] calldata _payees, uint[] calldata _shares)
        external {
        require(_totalAmount > 0, "Invalid arguments: Total hold amount should be greater than 0");
        require(_payees.length > 0, "Invalid arguments: Number of payees should be greater than 0");
        require(_payees.length == _shares.length, "Invalid arguments: Number of payees and shares not matched");
        uint sum = 0;
        for (uint i = 0; i < _shares.length;) {
            require(_shares[i] > 0, "Invalid arguments: All shares should be greater than 0");
            sum += _shares[i];
            unchecked { i++; }
        }
        require(token.transferFrom(msg.sender, address(this), _totalAmount), "Cannot transferFrom");
        require(_totalAmount >= sum, "Invalid arguments: Sum of shares cannot be greater than total payment");
        require(insertHold(_uuid, msg.sender, _totalAmount, _payees, _shares), "Cannot insert hold");
    }
    function revoke(string calldata _uuid)
        external
        onlyOwner
        UUIDExists(_uuid) {
        require(token.transfer(holdOfUUID[_uuid].payer, holdOfUUID[_uuid].paid), "Cannot transfer token");
        require(deleteHold(_uuid), "Cannot delete hold");
    }
    function fulfill(string calldata _uuid)
        external
        onlyOwner
        UUIDExists(_uuid) {
        for (uint i = 0; i < holdOfUUID[_uuid].payees.length;) {
            require(token.transfer(holdOfUUID[_uuid].payees[i], holdOfUUID[_uuid].shares[i]), "Cannot transfer token");
            unchecked { i++; }
        }
        require(deleteHold(_uuid), "Cannot delete hold");
    }
    function insertHold(string calldata _uuid, address _payer, uint _totalAmount, address[] calldata _payees, uint[] calldata _shares)
        private
        UUIDNotExists(_uuid)
        returns (bool) {
        allocOfUUID[_uuid] = true;
        holdOfUUID[_uuid] = Hold({ payer:_payer, paid:_totalAmount, payees:_payees, shares:_shares });
        return true;
    }
    function deleteHold(string calldata _uuid)
        private
        UUIDExists(_uuid)
        returns (bool) {
        // allocOfUUID[_uuid] = false;
        delete allocOfUUID[_uuid];
        delete holdOfUUID[_uuid];
        return true;
    }
    modifier UUIDNotExists(string calldata uuid) {
        require (allocOfUUID[uuid] == false, "UUID conflict");
        _;
    }
    modifier UUIDExists(string calldata uuid) {
        require (allocOfUUID[uuid] == true, "UUID does not exist");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the operator can do this action");
        _;
    }
}