// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libs/Vault.sol";
import "./ISwap.sol";

interface IRibbonThetaVaultWithSwap {
    event OpenShort(
        address indexed options,
        uint256 depositAmount,
        address indexed manager
    );

    event CloseShort(
        address indexed options,
        uint256 withdrawAmount,
        address indexed manager
    );

    event NewOptionStrikeSelected(uint256 strikePrice, uint256 delta);

    event AuctionDurationSet(
        uint256 auctionDuration,
        uint256 newAuctionDuration
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event NewOffer(
        uint256 swapId,
        address seller,
        address oToken,
        address biddingToken,
        uint256 minPrice,
        uint256 minBidSize,
        uint256 totalSize
    );

    /************************************************
     *  STRUCTS
     ***********************************************/

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param _strikeSelection is the address of the contract with strike selection logic
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _optionsPremiumPricer;
        address _strikeSelection;
    }

    /**
     * @notice Sets the new strike selection contract
     * @param newStrikeSelection is the address of the new strike selection contract
     */
    function setStrikeSelection(address newStrikeSelection) external;

    /**
     * @notice Sets the new options premium pricer contract
     * @param newOptionsPremiumPricer is the address of the new strike selection contract
     */
    function setOptionsPremiumPricer(address newOptionsPremiumPricer) external;

    /**
     * @notice Optionality to set strike price manually
     * Should be called after closeRound if we are setting current week's strike
     * @param strikePrice is the strike price of the new oTokens (decimals = 8)
     */
    function setStrikePrice(uint128 strikePrice) external;

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    function setLiquidityGauge(address newLiquidityGauge) external;

    /**
     * @notice Sets oToken Premium
     * @param minPrice is the new oToken Premium in the units of 10**18
     */
    function setMinPrice(uint256 minPrice) external;

    /**
     * @notice Sets the new Vault Pauser contract for this vault
     * @param newVaultPauser is the address of the new vaultPauser contract
     */
    function setVaultPauser(address newVaultPauser) external;

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external;

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external;

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external;

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    function stake(uint256 numShares) external;

    /**
     * @notice Closes the existing short and calculate the shares to mint, new price per share &
      amount of funds to re-allocate as collateral for the new round
     * Since we are incrementing the round here, the options are sold in the beginning of a round
     * instead of at the end of the round. For example, at round 1, we don't sell any options. We
     * start selling options at the beginning of round 2.
     */
    function closeRound() external;

    /**
     * @notice Sets the next option the vault will be shorting
     */
    function commitNextOption() external;

    /**
     * @notice Rolls the vault's funds into a new short position and create a new offer.
     */
    function rollToNextOption() external;

    /**
     * @notice Settle current offer
     */
    function settleOffer(ISwap.Bid[] calldata bids) external;

    /**
     * @notice Burn the remaining oTokens left over
     */
    function burnRemainingOTokens() external;

    /**
     * @notice pause a user's vault position
     */
    function pausePosition() external;
}
