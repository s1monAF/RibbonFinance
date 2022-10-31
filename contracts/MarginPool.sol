// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/IMarginPool.sol";

/**
 * @author Opyn Team
 * @title MarginPool
 * @notice Contract that holds all protocol funds
 */
contract MarginPool is IMarginPool, Ownable {
    using SafeERC20 for IERC20;

    /// @notice AddressBook module
    address public override addressBook;
    /// @dev the address that has the ability to withdraw excess assets in the pool
    address public override farmer;
    /// @dev mapping between an asset and the amount of the asset in the pool
    mapping(address => uint256) internal assetBalance;

    /**
     * @notice contructor
     * @param _addressBook AddressBook module
     */
    constructor(address _addressBook) {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /**
     * @notice check if the sender is the Controller module
     */
    modifier onlyController() {
        require(
            msg.sender == IAddressBook(addressBook).getController(),
            "MarginPool: Sender is not Controller"
        );

        _;
    }

    /**
     * @notice check if the sender is the farmer address
     */
    modifier onlyFarmer() {
        require(msg.sender == farmer, "MarginPool: Sender is not farmer");

        _;
    }

    /**
     * @notice transfers an asset from a user to the pool
     * @param _asset address of the asset to transfer
     * @param _user address of the user to transfer assets from
     * @param _amount amount of the token to transfer from _user
     */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) public override onlyController {
        require(_amount > 0, "MarginPool: transferToPool amount is equal to 0");
        assetBalance[_asset] += _amount;

        // transfer _asset _amount from _user to pool
        IERC20(_asset).safeTransferFrom(_user, address(this), _amount);
        emit TransferToPool(_asset, _user, _amount);
    }

    /**
     * @notice transfers an asset from the pool to a user
     * @param _asset address of the asset to transfer
     * @param _user address of the user to transfer assets to
     * @param _amount amount of the token to transfer to _user
     */
    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) public override onlyController {
        require(
            _user != address(this),
            "MarginPool: cannot transfer assets to oneself"
        );
        assetBalance[_asset] -= _amount;

        // transfer _asset _amount from pool to _user
        IERC20(_asset).safeTransfer(_user, _amount);
        emit TransferToUser(_asset, _user, _amount);
    }

    /**
     * @notice get the stored balance of an asset
     * @param _asset asset address
     * @return asset balance
     */
    function getStoredBalance(address _asset)
        external
        view
        override
        returns (uint256)
    {
        return assetBalance[_asset];
    }

    /**
     * @notice transfers multiple assets from users to the pool
     * @param _asset addresses of the assets to transfer
     * @param _user addresses of the users to transfer assets to
     * @param _amount amount of each token to transfer to pool
     */
    function batchTransferToPool(
        address[] memory _asset,
        address[] memory _user,
        uint256[] memory _amount
    ) external override onlyController {
        require(
            _asset.length == _user.length && _user.length == _amount.length,
            "MarginPool: batchTransferToPool array lengths are not equal"
        );

        for (uint256 i = 0; i < _asset.length; i++) {
            // transfer _asset _amount from _user to pool
            transferToPool(_asset[i], _user[i], _amount[i]);
        }
    }

    /**
     * @notice transfers multiple assets from the pool to users
     * @param _asset addresses of the assets to transfer
     * @param _user addresses of the users to transfer assets to
     * @param _amount amount of each token to transfer to _user
     */
    function batchTransferToUser(
        address[] memory _asset,
        address[] memory _user,
        uint256[] memory _amount
    ) external override onlyController {
        require(
            _asset.length == _user.length && _user.length == _amount.length,
            "MarginPool: batchTransferToUser array lengths are not equal"
        );

        for (uint256 i = 0; i < _asset.length; i++) {
            // transfer _asset _amount from pool to _user
            transferToUser(_asset[i], _user[i], _amount[i]);
        }
    }

    /**
     * @notice function to collect the excess balance of a particular asset
     * @dev can only be called by the farmer address. Do not farm otokens.
     * @param _asset asset address
     * @param _receiver receiver address
     * @param _amount amount to remove from pool
     */
    function farm(
        address _asset,
        address _receiver,
        uint256 _amount
    ) external override onlyFarmer {
        require(
            _receiver != address(0),
            "MarginPool: invalid receiver address"
        );

        uint256 externalBalance = IERC20(_asset).balanceOf(address(this));
        uint256 storedBalance = assetBalance[_asset];

        require(
            _amount <= externalBalance - storedBalance,
            "MarginPool: amount to farm exceeds limit"
        );

        IERC20(_asset).safeTransfer(_receiver, _amount);

        emit AssetFarmed(_asset, _receiver, _amount);
    }

    /**
     * @notice function to set farmer address
     * @dev can only be called by MarginPool owner
     * @param _farmer farmer address
     */
    function setFarmer(address _farmer) external override onlyOwner {
        emit FarmerUpdated(farmer, _farmer);

        farmer = _farmer;
    }
}
