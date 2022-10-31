// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestingWETH is ERC20 {
    constructor() ERC20("Testing WETH", "tWETH") {
        _mint(msg.sender, 1_000_000_000 * 1e18);
    }
}
