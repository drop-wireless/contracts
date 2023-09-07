// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BatchTransferTF {    // transferFrom: 6.977602 for 354 transfers + approve
    ERC20 public token;
    constructor(address _token) {
        token = ERC20(_token);
    }
    function batchTransfer(address[] calldata toAddresses, uint256[] calldata amounts) external {
        require(toAddresses.length == amounts.length, "Invalid input parameters");
        
        for(uint256 i = 0; i < toAddresses.length;) {
            require(token.transferFrom(msg.sender, toAddresses[i], amounts[i]), "Unable to transfer token to the account");
            unchecked { i++; } 
        }
    }
}
contract BatchTransferDP {   // direct payment: 5.864492 for 354 transfers + transfer for top up balance of contract
    ERC20 public token;
    address public operator;

    constructor(address _token) {
        operator = msg.sender;
        token = ERC20(_token);
    }
    function batchTransfer(address[] calldata toAddresses, uint256[] calldata amounts) external {
        require(operator == msg.sender, "Only the operator can do this action");
        require(toAddresses.length == amounts.length, "Invalid input parameters");
        
        for(uint256 i = 0; i < toAddresses.length;) {
            require(token.transfer(toAddresses[i], amounts[i]), "Unable to transfer token to the account");
            unchecked { i++; } 
        }
    }
}
contract BatchTransferDPWD {   // direct payment + withdrawable + ownership transfer : 5.864514 for 354 accounts +  transfer for top up balance of contract
    ERC20 public token;
    address public owner;

    constructor(address _token) {
        owner = msg.sender;
        token = ERC20(_token);
    }
    function transferOwnership(address newOnwer)
        external
        onlyOwner {
        owner = newOnwer;
    }
    function withdraw(uint amount)
        external
        onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Not enough balance in the contract");
        require(token.transfer(msg.sender, amount), "Unable to transfer token to the owner account");
    }
    function batchTransfer(address[] calldata toAddresses, uint[] calldata amounts)
        external
        onlyOwner {
        require(toAddresses.length == amounts.length, "Invalid input parameters");
        
        for(uint i = 0; i < toAddresses.length;) {
            require(token.transfer(toAddresses[i], amounts[i]), "Unable to transfer token to the account");
            unchecked { i++; } 
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the operator can do this action");
        _;
    }
}