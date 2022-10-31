// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestingUSDC is ERC20 {
    constructor() ERC20("Testing USDC", "tUSDC") {
        _mint(msg.sender, 1_000_000_000 * 1e18);
    }
}
