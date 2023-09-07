// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract usingERC20 {
    IERC20 internal token;
    address public tokenAddress;
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
    }
}
