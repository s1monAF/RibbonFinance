// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracle {
    /// @dev structure that stores price of asset and timestamp when the price was stored
    struct Price {
        uint256 price;
        uint256 timestamp; // timestamp at which the price is pushed to this oracle
    }
    /// @notice emits an event when the disputer is updated
    event DisputerUpdated(address indexed newDisputer);
    /// @notice emits an event when the pricer is updated for an asset
    event PricerUpdated(address indexed asset, address indexed pricer);
    /// @notice emits an event when the locking period is updated for a pricer
    event PricerLockingPeriodUpdated(
        address indexed pricer,
        uint256 lockingPeriod
    );
    /// @notice emits an event when the dispute period is updated for a pricer
    event PricerDisputePeriodUpdated(
        address indexed pricer,
        uint256 disputePeriod
    );
    /// @notice emits an event when an expiry price is updated for a specific asset
    event ExpiryPriceUpdated(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 price,
        uint256 onchainTimestamp
    );
    /// @notice emits an event when the disputer disputes a price during the dispute period
    event ExpiryPriceDisputed(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 disputedPrice,
        uint256 newPrice,
        uint256 disputeTimestamp
    );
    /// @notice emits an event when a stable asset price changes
    event StablePriceUpdated(address indexed asset, uint256 price);

    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp)
        external
        view
        returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp)
        external
        view
        returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp)
        external
        view
        returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer)
        external
        view
        returns (uint256);

    function getPricerDisputePeriod(address _pricer)
        external
        view
        returns (uint256);

    function getChainlinkRoundData(address _asset, uint80 _roundId)
        external
        view
        returns (uint256, uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}
