// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMarginPool {
    /// @notice emits an event when marginpool receive funds from controller
    event TransferToPool(
        address indexed asset,
        address indexed user,
        uint256 amount
    );
    /// @notice emits an event when marginpool transfer funds to controller
    event TransferToUser(
        address indexed asset,
        address indexed user,
        uint256 amount
    );
    /// @notice emit event after updating the farmer address
    event FarmerUpdated(address indexed oldAddress, address indexed newAddress);
    /// @notice emit event when an asset gets harvested from the pool
    event AssetFarmed(
        address indexed asset,
        address indexed receiver,
        uint256 amount
    );

    /* Getters */
    function addressBook() external view returns (address);

    function farmer() external view returns (address);

    function getStoredBalance(address _asset) external view returns (uint256);

    /* Admin-only functions */
    function setFarmer(address _farmer) external;

    function farm(
        address _asset,
        address _receiver,
        uint256 _amount
    ) external;

    /* Controller-only functions */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function batchTransferToPool(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;

    function batchTransferToUser(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;
}
