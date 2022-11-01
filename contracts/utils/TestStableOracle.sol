// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract TestStableOracle {
    uint256 public answer;

    constructor(uint256 initAnswer) {
        answer = initAnswer;
    }

    function setAnswer(uint256 _answer) external {
        answer = _answer;
    }

    function decimals() external pure returns (uint256) {
        return 8;
    }

    function latestAnswer() external view returns (uint256) {
        return answer;
    }
}
