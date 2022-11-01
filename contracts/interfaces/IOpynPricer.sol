// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOpynPricer {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(uint80 _roundId)
        external
        view
        returns (uint256, uint256);
}
