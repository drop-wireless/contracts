// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./base.sol";

contract ExampleDevice is usingERC20 {
    constructor(address _tokenAddress) usingERC20(_tokenAddress) {
    }
    struct Stake {
        uint amount;
        address holder;
        uint deviceID;
        uint from;
    }
    // device ID =>
    mapping (uint=>Stake[]) stakersOf;      // mapping (uint => mapping (address => stake)) stakeOf;
    mapping (uint=>uint) earningOf;
    
    // user =>
    mapping (address=>Stake[]) stakesOf;


    function buyService(uint _deviceID, uint _amount, byte data) public returns(bool){
        earningOf[_deviceID] += _amount;

        // do stuff with data

        return transferFrom(msg.sender, address(this), _amount);
    }
    // function getDividend() {
    //     for (uint i = 0; i <)
    // }
}