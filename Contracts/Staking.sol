// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./base.sol";

// Stake
uint constant MINIMUM_STAKE_AMOUNT = 500;
uint constant MINIMUM_STAKE_PERIOD = 60; //86400; // in seconds

contract Staking is usingERC20 {
    struct Stake {
        uint256 amount;
        uint256 startedAt;    // minimum locking period ?
    }

    mapping(address => Stake) stakeOf;
    address[] stakers;  // this may be needed when we want to look up whole stakers
    constructor(address _tokenAddress) usingERC20(_tokenAddress) {
    }

    function totalStaked() external view returns(uint256) {
        uint256 amount = token.balanceOf(address(this));  // only internal calls?
        return amount;
    }
    function addStake(uint256 _amount) external returns(bool) {
        require(_amount >= MINIMUM_STAKE_AMOUNT, "Does not meet MINIMUM_STAKE_AMOUNT.");    // TO DO: string.concat

        if (stakeOf[msg.sender].amount == 0) {  // first time stake
            stakers.push(msg.sender);
            stakeOf[msg.sender] = Stake({ amount: _amount, startedAt: block.timestamp });
        }
        else {
            stakeOf[msg.sender].amount += _amount;
            // if we refresh the time stamp, redeemStakingReward() here.
            stakeOf[msg.sender].startedAt = block.timestamp;   // refresh the timestamp? or keep it?
        }
        return token.transferFrom(msg.sender, address(this), _amount);
    }
    function unstake() external stakersOnly returns(bool) {
        require(stakeOf[msg.sender].startedAt + MINIMUM_STAKE_PERIOD >= block.timestamp, "Cannot unstake until MINIMUM_STAKE_PERIOD.");
        // redeemStakingReward() here.
        uint amount = stakeOf[msg.sender].amount;
        // remove address from the list // this list can be long // just swap with the last item and pop it
        for (uint i = 1; i < stakers.length-1; i++) {
            if (stakers[i] == msg.sender) {
                stakers[i] = stakers[stakers.length-1];
                break;
            }
        }
        stakers.pop();
        return token.transferFrom(address(this), msg.sender, amount);
    }
    function estimateReward() public stakersOnly view returns(uint256) {

        // TO DO: put reward calculation algorithm here,
        // revert ("Not Yet Implemented");
        return stakeOf[msg.sender].amount / 10;
    }
    function redeemRewards() external stakersOnly returns(bool){
        require (estimateReward() > 0, "There is no redeemable rewards.");
        
        // TO DO: put reward redeeming algorithm here,
        //      this should be done within the total staked amount, otherwise will be broken.
        revert ("Not Yet Implemented");
        // uint256 amount = 5000;

        // // return false;
        // return nnit.transferFrom(address(this), msg.sender, amount);
    }
    modifier stakersOnly() {
        require(stakeOf[msg.sender].amount > 0, "Only the stakers can perform this action.");
        _;
    }
}