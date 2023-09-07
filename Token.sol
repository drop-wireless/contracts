// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

// External Libraries
import "@openzeppelin/contracts/utils/Strings.sol"; // to use toString(uint), also includes Math

// Token
string constant NAME = "test NNIT";
string constant SYMBOL = "NNIT-T";
uint8 constant DECIMALS = 18;    // 18
uint256 constant SUPPLY_CAP = 10**(9+DECIMALS); // 1B

// Mint
uint8 constant MINIMUM_SIGNERS = 2;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Deposit(address indexed sender, uint amount, uint balance);
}
contract owned {
    address public owner;
    constructor(){
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) 
        public
        ownerOnly {
        owner = _newOwner;
    }
    modifier ownerOnly() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }
}
contract Token is IERC20, owned {
// Token Info
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    uint public supplyCap;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(address[] memory _minters, uint _numOfSignsRequired) 
        validNumberOfApprovals(_numOfSignsRequired)
        owned() {
        require(_minters.length >= _numOfSignsRequired, "The number of minters should be greater than the number of signs required.");
        name = NAME;
        symbol = SYMBOL;
        decimals = DECIMALS;
        totalSupply = 0;
        supplyCap = SUPPLY_CAP;

        for (uint i = 0; i < _minters.length; i++) {
            addMinter(_minters[i]);
        }
        setNumberOfSignsRequired(_numOfSignsRequired);
    }

    uint public signsRequired;
    mapping (address => bool) public isMinter;
    address[] minters;
    struct MintRequest {
        address requester;
        address receiver;
        uint amount;
        bool rejected;
        bool executed;
        address[] signers;  // this will not be included on default getter mintReuqests(0)
    }
    MintRequest[] public mintRequests;

    mapping (address => uint) balance; // total balance including locked.
    function balanceOf(address _account) external view returns(uint) {
        return balance[_account];
    }

    // event Minted(address indexed to, uint amount);   // duplicate of Transfer from 0x00
    event MintRequested(uint indexed mintID);

    //
    error NotYetImplemented();

    // receive() external payable {
    //     emit Deposit(msg.sender, msg.value, address(this).balance);
    // }

// Minter Management
    function setNumberOfSignsRequired(uint _n)
        private // public
        ownerOnly 
        validNumberOfApprovals(_n) {
        signsRequired = _n;
    }
    function mintersList() 
        external
        view 
        returns(address[] memory) {
        return minters;
    }
    function addMinter(address _newMinter)
        private // public
        ownerOnly {
        require(!isMinter[_newMinter] && _newMinter != address(0), "Already registered as minter, or invalid address.");
        isMinter[_newMinter] = true;
        minters.push(_newMinter);
    }
    // function removeMinter(address _minter)
    //     external
    //     ownerOnly {
    //     require(isMinter[_minter], "Not a minter.");
    //     isMinter[_minter] = false;
    //     uint index = 0;
    //     for (uint i = 1; i < minters.length; i++) {
    //         if (minters[i] == _minter) {
    //             index = i;
    //             break;
    //         }
    //     }
    //     for (uint i = index; i < minters.length-1; i++) {
    //         minters[i] = minters[i+1];
    //     }
    //     minters.pop();
    // }

// Multi-sig Mint
    function numberOfMintRequests() external view returns(uint) {
        return mintRequests.length;
    }
    function requestMint(address _receiver, uint _amount)
        external
        // minterOnly
        doNotExceedSupplyLimit(_amount)
        returns(uint) {
        mintRequests.push();    // push empty struct and put data
        uint id = mintRequests.length - 1;
        mintRequests[id].requester = msg.sender;
        mintRequests[id].receiver = _receiver;
        mintRequests[id].amount = _amount;
        mintRequests[id].rejected = false;
        mintRequests[id].executed = false;
        // mintRequests[id].signers = new address[];    //it is already initialized as empty array.
        
        emit MintRequested(id);
        return id;
    }
    // error DuplicateSigner(address signer, uint mintID);
    function signMint(uint _mintID)
        external
        minterOnly
        validMintId(_mintID)
        notDeterminedMintRequest(_mintID) 
        doNotExceedSupplyLimit(mintRequests[_mintID].amount) // this is probabily optional, but may affect UX, and cause waste of gas fee.
        returns(bool) {
        MintRequest storage request = mintRequests[_mintID];
        for (uint i = 0; i < request.signers.length; i++) {
            // duplicate signer
            require(request.signers[i] != msg.sender, "Already signed this mint request.");
            // if (request.signers[i] == msg.sender) 
            //     revert DuplicateSigner({ signer: msg.sender, mintID: _mintID });
        }
        request.signers.push(msg.sender);
        if (request.signers.length >= signsRequired) {
            _executeMint(_mintID);
        }
        return true;
    }
    function rejectMint(uint _mintID) 
        external
        minterOnly
        validMintId(_mintID)
        notDeterminedMintRequest(_mintID) {
        MintRequest storage request = mintRequests[_mintID];
        request.rejected = true;
    }
    function _executeMint(uint _mintID)
        internal 
        minterOnly
        validMintId(_mintID)
        notDeterminedMintRequest(_mintID)
        doNotExceedSupplyLimit(mintRequests[_mintID].amount) {
        MintRequest storage request = mintRequests[_mintID];
        request.executed = true;
        balance[request.receiver] += request.amount;
        totalSupply += request.amount;

        emit Transfer(address(0), request.receiver, request.amount);
        // emit Minted(request.receiver, request.amount);
    }
    function signersOf(uint _mintID) 
        external
        view 
        validMintId(_mintID) // TO DO: invalid mint id passes through and generates overflow error. works fine on other functions. 
        returns(address[] memory) {
        return mintRequests[_mintID].signers;
    }

// IERC20, Basic Wallet Methods
    function transfer(address _receiver, uint _amount)
        external
        sufficientBalance(msg.sender, _amount) 
        returns(bool) {
        balance[msg.sender] -= _amount;
        balance[_receiver] += _amount;

        emit Transfer({ from:msg.sender, to:_receiver, value:_amount });
        return true;
    }
    function approve(address _spender, uint _amount)
        external
        sufficientBalance(msg.sender, _amount)
        returns(bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    function transferFrom(address _sender, address _recipient, uint _amount)
        external
        sufficientBalance(_sender, _amount)
        returns(bool) {
        require(allowance[_sender][msg.sender] >= _amount, "The amount exceeds the allowance. Need to approve the amount to the contract or other account before they use your tokens.");
        allowance[_sender][msg.sender] -= _amount;
        balance[_sender] -= _amount;
        balance[_recipient] += _amount;
        emit Transfer({ from:_sender, to:_recipient, value:_amount });
        return true;
    }

// Modifiers
    modifier sufficientBalance(address account, uint amount) {
        require(balance[account] >= amount, "Insufficient balance.");
        _;
    }
    modifier minterOnly() {
        require(isMinter[msg.sender] && msg.sender != address(0), "Only registered minter can perform this action.");
        _;
    }
    modifier validMintId(uint _id) {
        require(_id < mintRequests.length, "Invalid mint ID.");
        _;
    }
    modifier notDeterminedMintRequest(uint _id) {
        require(!mintRequests[_id].rejected && !mintRequests[_id].executed, "Already rejected or executed mint ID.");
        _;
    }
    modifier validNumberOfApprovals(uint _n) {
        require(_n >= MINIMUM_SIGNERS, string.concat("Number of signers cannot be set to less than ", Strings.toString(MINIMUM_SIGNERS))); // TO DO: string.concat
        // require(_n > 1, "Less than 2 minter approval is not alllowed.");
        _;
    }
    modifier doNotExceedSupplyLimit(uint _toMint) {
        require(totalSupply + _toMint <= supplyCap, "Cannot exceed the limit of total supply.");
        _;
    }


///////////////////////////////////////////
// TO DO: remove below test methods
    // function testFaucet(address _receiver, uint _amount) 
    //     external
    //     ownerOnly 
    //     doNotExceedSupplyLimit(_amount) {
    //     balance[_receiver] += _amount;
    //     totalSupply += _amount;
    //     emit Transfer(address(0), _receiver, _amount);
    //     emit Minted(_receiver, _amount);
    // }
    // function testBurn(address _spender, uint _amount) 
    //     external
    //     ownerOnly
    //     sufficientBalance(_spender, _amount) {
    //     balance[_spender] -= _amount;
    //     totalSupply -= _amount;
    //     emit Transfer(_spender, address(0), _amount);
    // }
//////////////////////////////////////

}