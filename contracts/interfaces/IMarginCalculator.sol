// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libs/MarginVault.sol";

interface IMarginCalculator {
    /// @dev struct to store all needed vault details
    struct VaultDetails {
        address shortUnderlyingAsset;
        address shortStrikeAsset;
        address shortCollateralAsset;
        address longUnderlyingAsset;
        address longStrikeAsset;
        address longCollateralAsset;
        uint256 shortStrikePrice;
        uint256 shortExpiryTimestamp;
        uint256 shortCollateralDecimals;
        uint256 longStrikePrice;
        uint256 longExpiryTimestamp;
        uint256 longCollateralDecimals;
        uint256 collateralDecimals;
        uint256 vaultType;
        bool isShortPut;
        bool isLongPut;
        bool hasLong;
        bool hasShort;
        bool hasCollateral;
    }

    /// @notice emits an event when collateral dust is updated
    event CollateralDustUpdated(address indexed collateral, uint256 dust);
    /// @notice emits an event when new time to expiry is added for a specific product
    event TimeToExpiryAdded(bytes32 indexed productHash, uint256 timeToExpiry);
    /// @notice emits an event when new upper bound value is added for a specific time to expiry timestamp
    event MaxPriceAdded(
        bytes32 indexed productHash,
        uint256 timeToExpiry,
        uint256 value
    );
    /// @notice emits an event when updating upper bound value at specific expiry timestamp
    event MaxPriceUpdated(
        bytes32 indexed productHash,
        uint256 timeToExpiry,
        uint256 oldValue,
        uint256 newValue
    );
    /// @notice emits an event when spot shock value is updated for a specific product
    event SpotShockUpdated(bytes32 indexed product, uint256 spotShock);
    /// @notice emits an event when oracle deviation value is updated
    event OracleDeviationUpdated(uint256 oracleDeviation);

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
