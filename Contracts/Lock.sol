// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./base.sol";

contract Lock is usingERC20 {
    struct LockedBalance {
        uint amount;
        uint posted;    // this is added to keep the order of the list.
        uint until;
    }
    mapping (address => LockedBalance[]) lockedOf;
    uint public totalLocked;    // to show the total amount of locked tokens.

    // event
    event LockedTransfer(address indexed from, address indexed to, uint amount, uint posted, uint until);
    
    constructor(address _tokenAddress) usingERC20(_tokenAddress) {
    }

// to make lock ups
    // put some tokens into the lock, and lock them until the given time.
    function lockedTransfer(address _to, uint _amount, uint _period) external returns(bool) {
        require(_to != address(0), "Cannot schedule a transfer to zero address");
        require(_amount > 0, "Transferring amount should be greater than 0");
        require(_period > 0, "Period should be greater than 0");
        uint current = block.timestamp;
        // store lock period
        lockedOf[_to].push(LockedBalance({ amount:_amount, posted:current, until:(current+_period) }));
        // increase total locked
        totalLocked += _amount;
        // transfer token to lock (this contract)
        bool transferResult = token.transferFrom(msg.sender, address(this), _amount);
        require (transferResult, "TransferFrom has been faield.");  // in case of transferFrom returns false without reverting.
        emit LockedTransfer(msg.sender, _to, _amount, current, current+_period);
        return true;
    }

// withdrawal
    // show all released tokens for given account.
    function readyToWithdrawOf(address _account)
        external
        view
        returns(uint) {
        uint toWithdraw = 0;
        uint current = block.timestamp;
        uint lockedOfLength = lockedOf[_account].length;
        for (uint i = 0; i < lockedOfLength; ) {
            if (current >= lockedOf[_account][i].until) {
                toWithdraw += lockedOf[_account][i].amount;
            }
            unchecked { i++; }
        }
        return toWithdraw;
    }
    // take all released tokens to given account.
    function withdrawOf(address _account)
        external
        returns(bool) {
        // count amount and remove withdrawed lock ups. This DOES NOT preserve the order of list.
        uint toWithdraw = 0;
        uint current = block.timestamp;
        uint lockedOfLength = lockedOf[_account].length;
        for (uint i = 0; i < lockedOfLength;) {
            uint j = lockedOf[_account].length-1-i; // reversed i
            if (current >= lockedOf[_account][j].until) {
                toWithdraw += lockedOf[_account][j].amount;
                lockedOf[_account][j] = lockedOf[_account][--lockedOfLength];   // swap with the last item, also it will be popped, so decrease the length by 1
                lockedOf[_account].pop();    // remove last item
            }
            unchecked { i++; }
        }
        require (toWithdraw > 0, "There is no token to withdraw.");
        // decrease the total locked, this is safe from underflow, guaranteed by logic
        unchecked { totalLocked -= toWithdraw; }
        // transfer them.
        bool transferResult = token.transfer(_account, toWithdraw);
        require (transferResult, "Transfer has been faield.");  // in case of transfer returns false without reverting.
        return true;
    }

// informations
    // show the all list of locked managed on this contract.
    function lockedListOf(address _account)
        external
        view
        returns(LockedBalance[] memory) {
        return lockedOf[_account];
    }
    // show current block time for reference.
    function blockTime() // this does not update immediately, providing approximate timestamp. 
        external
        view
        returns(uint) {
        return block.timestamp;
    }
}


