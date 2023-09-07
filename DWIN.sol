// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts@4.8.2/token/ERC20/ERC20.sol";

contract DWIN is ERC20 {
    constructor(address nestenInc, address nestenFoundation, address ecosystem)
        ERC20("Drop Wireless INfrastructure", "DWIN") {
        // premint 1.1B 
        uint million = 10 ** (6 + decimals());
        _mint(nestenInc, 200 * million);
        _mint(nestenFoundation, 200 * million);
        _mint(ecosystem, 700 * million);
    }
}
