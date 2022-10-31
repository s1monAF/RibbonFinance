// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWhitelist {
    /// @notice emits an event a product is whitelisted by the owner address
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event a product is blacklisted by the owner address
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event when a collateral address is whitelisted by the owner address
    event CollateralWhitelisted(address indexed collateral);
    /// @notice emits an event when a collateral address is blacklist by the owner address
    event CollateralBlacklisted(address indexed collateral);
    /// @notice emits an event when an oToken is whitelisted by the OtokenFactory module
    event OtokenWhitelisted(address indexed otoken);
    /// @notice emits an event when an oToken is blacklisted by the OtokenFactory module
    event OtokenBlacklisted(address indexed otoken);
    /// @notice emits an event when a callee address is whitelisted by the owner address
    event CalleeWhitelisted(address indexed _callee);
    /// @notice emits an event when a callee address is blacklisted by the owner address
    event CalleeBlacklisted(address indexed _callee);

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral)
        external
        view
        returns (bool);

    function isWhitelistedOtoken(address _otoken) external view returns (bool);

    function isWhitelistedCallee(address _callee) external view returns (bool);

    /* Admin / factory only functions */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function whitelistCollateral(address _collateral) external;

    function blacklistCollateral(address _collateral) external;

    function whitelistOtoken(address _otoken) external;

    function blacklistOtoken(address _otoken) external;

    function whitelistCallee(address _callee) external;

    function blacklistCallee(address _callee) external;
}
