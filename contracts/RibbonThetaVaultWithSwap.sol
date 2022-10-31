// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/ILiquidityGauge.sol";
import "./interfaces/IVaultPauser.sol";
import "./interfaces/IRibbonThetaVaultWithSwap.sol";
import "./interfaces/ISwap.sol";
import "./libs/VaultLifecycleWithSwap.sol";
import "./libs/ShareMath.sol";
import "./libs/Vault.sol";
import "./RibbonThetaVaultStorage.sol";
import "./RibbonVault.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in RibbonThetaVaultStorage.
 * RibbonThetaVault should not inherit from any other contract aside from RibbonVault, RibbonThetaVaultStorage
 */
contract RibbonThetaVaultWithSwap is
    IRibbonThetaVaultWithSwap,
    RibbonVault,
    RibbonThetaVaultStorage
{
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice oTokenFactory is the factory contract used to spawn otokens. Used to lookup otokens.
    address public immutable OTOKEN_FACTORY;

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _oTokenFactory is the contract address for minting new opyn option types (strikes, asset, expiry)
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _swapContract is the contract address that facilitates bids settlement
     */
    constructor(
        address _weth,
        address _usdc,
        address _oTokenFactory,
        address _gammaController,
        address _marginPool,
        address _swapContract
    ) RibbonVault(_weth, _usdc, _gammaController, _marginPool, _swapContract) {
        require(_oTokenFactory != address(0), "!_oTokenFactory");
        OTOKEN_FACTORY = _oTokenFactory;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        baseInitialize(
            _initParams._owner,
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _vaultParams
        );
        require(
            _initParams._optionsPremiumPricer != address(0),
            "!_optionsPremiumPricer"
        );
        require(
            _initParams._strikeSelection != address(0),
            "!_strikeSelection"
        );

        optionsPremiumPricer = _initParams._optionsPremiumPricer;
        strikeSelection = _initParams._strikeSelection;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new strike selection contract
     * @param newStrikeSelection is the address of the new strike selection contract
     */
    function setStrikeSelection(address newStrikeSelection) external onlyOwner {
        require(newStrikeSelection != address(0), "!newStrikeSelection");
        strikeSelection = newStrikeSelection;
    }

    /**
     * @notice Sets the new options premium pricer contract
     * @param newOptionsPremiumPricer is the address of the new strike selection contract
     */
    function setOptionsPremiumPricer(address newOptionsPremiumPricer)
        external
        onlyOwner
    {
        require(
            newOptionsPremiumPricer != address(0),
            "!newOptionsPremiumPricer"
        );
        optionsPremiumPricer = newOptionsPremiumPricer;
    }

    /**
     * @notice Optionality to set strike price manually
     * Should be called after closeRound if we are setting current week's strike
     * @param strikePrice is the strike price of the new oTokens (decimals = 8)
     */
    function setStrikePrice(uint128 strikePrice) external onlyOwner {
        require(strikePrice > 0, "!strikePrice");
        overriddenStrikePrice = strikePrice;
        lastStrikeOverrideRound = vaultState.round;
    }

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    function setLiquidityGauge(address newLiquidityGauge) external onlyOwner {
        liquidityGauge = newLiquidityGauge;
    }

    /**
     * @notice Sets oToken Premium
     * @param minPrice is the new oToken Premium in the units of 10**18
     */
    function setMinPrice(uint256 minPrice) external onlyKeeper {
        require(minPrice > 0, "!minPrice");
        currentOtokenPremium = minPrice;
    }

    /**
     * @notice Sets the new Vault Pauser contract for this vault
     * @param newVaultPauser is the address of the new vaultPauser contract
     */
    function setVaultPauser(address newVaultPauser) external onlyOwner {
        vaultPauser = newVaultPauser;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt = depositReceipts[
            msg.sender
        ];

        uint256 currentRound = vaultState.round;
        require(amount > 0, "!amount");
        require(depositReceipt.round == currentRound, "Invalid round");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = (receiptAmount - amount).toUint104();
        vaultState.totalPending = (uint256(vaultState.totalPending) - amount)
        .toUint128();

        emit InstantWithdraw(msg.sender, amount, currentRound);

        transferAsset(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares += numShares;
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = (uint256(lastQueuedWithdrawAmount) -
            withdrawAmount)
        .toUint128();
    }

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    function stake(uint256 numShares) external nonReentrant {
        address _liquidityGauge = liquidityGauge;
        require(_liquidityGauge != address(0)); // Removed revert msgs due to contract size limit
        require(numShares > 0);
        uint256 heldByAccount = balanceOf(msg.sender);
        if (heldByAccount < numShares) {
            _redeem(numShares - heldByAccount, false);
        }
        _transfer(msg.sender, address(this), numShares);
        _approve(address(this), _liquidityGauge, numShares);
        ILiquidityGauge(_liquidityGauge).deposit(numShares, msg.sender, false);
    }

    /**
     * @notice Closes the existing short and calculate the shares to mint, new price per share &
      amount of funds to re-allocate as collateral for the new round
     * Since we are incrementing the round here, the options are sold in the beginning of a round
     * instead of at the end of the round. For example, at round 1, we don't sell any options. We
     * start selling options at the beginning of round 2.
     */
    function closeRound() external nonReentrant {
        address oldOption = optionState.currentOption;
        require(
            oldOption != address(0) || vaultState.round == 1,
            "Round closed"
        );
        _closeShort(oldOption);

        uint256 currQueuedWithdrawShares = currentQueuedWithdrawShares;
        (
            ,
            uint256 lockedBalance,
            uint256 queuedWithdrawAmount
        ) = _rollToNextOption(
            uint256(lastQueuedWithdrawAmount),
            currQueuedWithdrawShares
        );

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares = uint256(
            vaultState.queuedWithdrawShares
        ) + currQueuedWithdrawShares;
        vaultState.queuedWithdrawShares = newQueuedWithdrawShares.toUint128();

        currentQueuedWithdrawShares = 0;

        vaultState.lockedAmount = lockedBalance.toUint104();

        uint256 nextOptionReady = block.timestamp + DELAY;
        require(
            nextOptionReady <= type(uint32).max,
            "Overflow nextOptionReady"
        );
        optionState.nextOptionReadyAt = nextOptionReady.toUint32();
    }

    /**
     * @notice Closes the existing short position for the vault.
     */
    function _closeShort(address oldOption) private {
        uint256 lockedAmount = vaultState.lockedAmount;
        if (oldOption != address(0)) {
            vaultState.lastLockedAmount = lockedAmount.toUint104();
        }
        vaultState.lockedAmount = 0;

        optionState.currentOption = address(0);

        if (oldOption != address(0)) {
            uint256 withdrawAmount = VaultLifecycleWithSwap.settleShort(
                GAMMA_CONTROLLER
            );
            emit CloseShort(oldOption, withdrawAmount, msg.sender);
        }
    }

    /**
     * @notice Sets the next option the vault will be shorting
     */
    function commitNextOption() external onlyKeeper nonReentrant {
        address currentOption = optionState.currentOption;
        require(
            currentOption == address(0) && vaultState.round != 1,
            "Round not closed"
        );


            VaultLifecycleWithSwap.CommitParams memory commitParams
         = VaultLifecycleWithSwap.CommitParams({
            OTOKEN_FACTORY: OTOKEN_FACTORY,
            USDC: USDC,
            collateralAsset: vaultParams.asset,
            currentOption: currentOption,
            delay: DELAY,
            lastStrikeOverrideRound: lastStrikeOverrideRound,
            overriddenStrikePrice: overriddenStrikePrice,
            strikeSelection: strikeSelection,
            optionsPremiumPricer: optionsPremiumPricer
        });

        (
            address otokenAddress,
            uint256 strikePrice,
            uint256 delta
        ) = VaultLifecycleWithSwap.commitNextOption(
            commitParams,
            vaultParams,
            vaultState
        );

        emit NewOptionStrikeSelected(strikePrice, delta);

        optionState.nextOption = otokenAddress;
    }

    /**
     * @notice Rolls the vault's funds into a new short position and create a new offer.
     */
    function rollToNextOption() external onlyKeeper nonReentrant {
        address newOption = optionState.nextOption;
        require(newOption != address(0), "!nextOption");

        optionState.currentOption = newOption;
        optionState.nextOption = address(0);
        uint256 lockedBalance = vaultState.lockedAmount;

        emit OpenShort(newOption, lockedBalance, msg.sender);

        VaultLifecycleWithSwap.createShort(
            GAMMA_CONTROLLER,
            MARGIN_POOL,
            newOption,
            lockedBalance
        );

        _createOffer();
    }

    function _createOffer() private {
        address currentOtoken = optionState.currentOption;
        uint256 currOtokenPremium = currentOtokenPremium;

        optionAuctionID = VaultLifecycleWithSwap.createOffer(
            currentOtoken,
            currOtokenPremium,
            GNOSIS_EASY_AUCTION,
            vaultParams
        );
    }

    /**
     * @notice Settle current offer
     */
    function settleOffer(ISwap.Bid[] calldata bids)
        external
        onlyKeeper
        nonReentrant
    {
        ISwap(GNOSIS_EASY_AUCTION).settleOffer(optionAuctionID, bids);
    }

    /**
     * @notice Burn the remaining oTokens left over
     */
    function burnRemainingOTokens() external onlyKeeper nonReentrant {
        VaultLifecycleWithSwap.burnOtokens(
            GAMMA_CONTROLLER,
            optionState.currentOption
        );
    }

    /**
     * @notice pause a user's vault position
     */
    function pausePosition() external {
        address _vaultPauserAddress = vaultPauser;
        require(_vaultPauserAddress != address(0)); // Removed revert msgs due to contract size limit
        _redeem(0, true);
        uint256 heldByAccount = balanceOf(msg.sender);
        _approve(msg.sender, _vaultPauserAddress, heldByAccount);
        IVaultPauser(_vaultPauserAddress).pausePosition(
            msg.sender,
            heldByAccount
        );
    }
}
