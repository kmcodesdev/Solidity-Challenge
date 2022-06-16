// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DevUSDC is ERC20 {
    constructor() public ERC20("Dev USDC", "DUSD") {
        _mint(msg.sender, 1000000000000000000000000);
    }
}
