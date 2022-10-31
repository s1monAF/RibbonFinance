// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceOracle {
    function decimals() external view returns (uint256 _decimals);

    function latestAnswer() external view returns (uint256 price);
}
