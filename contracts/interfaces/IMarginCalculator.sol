// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libs/MarginVault.sol";

interface IMarginCalculator {
    function addressBook() external view returns (address);

    function getExpiredPayoutRate(address _otoken)
        external
        view
        returns (uint256);

    function getExcessCollateral(
        MarginVault.Vault calldata _vault,
        uint256 _vaultType
    ) external view returns (uint256 netValue, bool isExcess);

    function isLiquidatable(
        MarginVault.Vault memory _vault,
        uint256 _vaultType,
        uint256 _vaultLatestUpdate,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}
