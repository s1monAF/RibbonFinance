//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IManualVolatilityOracle.sol";
import "./libs/DSMath.sol";
import "./libs/Math.sol";

import "hardhat/console.sol";

contract OptionsPremiumPricerInStables {
    bytes32 public immutable optionId;
    IManualVolatilityOracle public immutable volatilityOracle;
    IPriceOracle public immutable priceOracle;
    IPriceOracle public immutable stablesOracle;
    uint256 private immutable _priceOracleDecimals;
    uint256 private immutable _stablesOracleDecimals;

    // For reference - IKEEP3rVolatility: 0xCCdfCB72753CfD55C5afF5d98eA5f9C43be9659d

    /**
     * @notice Constructor for pricer, deploy one for every optionId
     * @param _optionId is the bytes32 of the Option struct specifiying collateral, underlying, delta, and isPut
     * @param _volatilityOracle is the oracle for historical volatility
     * @param _priceOracle is the Chainlink price oracle for the underlying asset
     * @param _stablesOracle is the Chainlink price oracle for the strike asset (e.g. USDC)
     */
    constructor(
        bytes32 _optionId,
        address _volatilityOracle,
        address _priceOracle,
        address _stablesOracle
    ) {
        require(_optionId.length > 0, "!_optionId");
        require(_volatilityOracle != address(0), "!_volatilityOracle");
        require(_priceOracle != address(0), "!_priceOracle");
        require(_stablesOracle != address(0), "!_stablesOracle");

        optionId = _optionId;
        volatilityOracle = IManualVolatilityOracle(_volatilityOracle);
        priceOracle = IPriceOracle(_priceOracle);
        stablesOracle = IPriceOracle(_stablesOracle);
        _priceOracleDecimals = IPriceOracle(_priceOracle).decimals();
        _stablesOracleDecimals = IPriceOracle(_stablesOracle).decimals();
    }

    /**
     * @notice Calculates the premium of the provided option using Black-Scholes
     * References for Black-Scholes:
       https://www.macroption.com/black-scholes-formula/
       https://www.investopedia.com/terms/b/blackscholes.asp
       https://www.erieri.com/blackscholes
       https://goodcalculators.com/black-scholes-calculator/
       https://www.calkoo.com/en/black-scholes-option-pricing-model
     * @param st is the strike price of the option
     * @param expiryTimestamp is the unix timestamp of expiry
     * @param isPut is whether the option is a put option
     * @return premium for 100 contracts with 18 decimals i.e.
     * 500*10**18 = 500 USDC for 100 contracts for puts,
     * 5*10**18 = 5 of underlying asset (ETH, WBTC, etc.) for 100 contracts for calls,
     */
    function getPremium(
        uint256 st,
        uint256 expiryTimestamp,
        bool isPut
    ) external view returns (uint256 premium) {
        uint256 sp = priceOracle.latestAnswer();
        (uint256 assetPrice, uint256 assetDecimals) = isPut
            ? (stablesOracle.latestAnswer(), _stablesOracleDecimals)
            : (sp, _priceOracleDecimals);

        premium = _getPremium(
            st,
            sp,
            expiryTimestamp,
            assetPrice,
            assetDecimals,
            isPut
        );
    }

    /**
     * @notice Calculates the premium of the provided option using Black-Scholes in stables
     * @param st is the strike price of the option
     * @param expiryTimestamp is the unix timestamp of expiry
     * @param isPut is whether the option is a put option
     * @return premium for 100 contracts with 18 decimals
     */
    function getPremiumInStables(
        uint256 st,
        uint256 expiryTimestamp,
        bool isPut
    ) external view returns (uint256 premium) {
        premium = _getPremium(
            st,
            priceOracle.latestAnswer(),
            expiryTimestamp,
            stablesOracle.latestAnswer(),
            _stablesOracleDecimals,
            isPut
        );
    }

    /**
     * @notice Internal function to calculate the premium of the provided option using Black-Scholes
     * @param st is the strike price of the option
     * @param sp is the spot price of the underlying asset
     * @param expiryTimestamp is the unix timestamp of expiry
     * @param assetPrice is the denomination asset for the options
     * @param assetDecimals is the decimals points of the denomination asset price
     * @param isPut is whether the option is a put option
     * @return premium for 100 contracts with 18 decimals
     */
    function _getPremium(
        uint256 st,
        uint256 sp,
        uint256 expiryTimestamp,
        uint256 assetPrice,
        uint256 assetDecimals,
        bool isPut
    ) internal view returns (uint256 premium) {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        uint256 v;
        uint256 t;
        (sp, v, t) = blackScholesParams(sp, expiryTimestamp);

        (uint256 call, uint256 put) = quoteAll(t, v, sp, st);

        // Multiplier to convert oracle latestAnswer to 18 decimals
        uint256 assetOracleMultiplier = 10**(uint256(18) - assetDecimals);

        // Make option premium denominated in the underlying
        // asset for call vaults and USDC for put vaults
        premium = isPut
            ? DSMath.wdiv(put, assetPrice * assetOracleMultiplier)
            : DSMath.wdiv(call, assetPrice * assetOracleMultiplier);

        // Convert to 18 decimals
        premium *= assetOracleMultiplier;
    }

    /**
     * @notice Calculates the option's delta
     * Formula reference: `d_1` in https://www.investopedia.com/terms/b/blackscholes.asp
     * http://www.optiontradingpedia.com/options_delta.htm
     * https://www.macroption.com/black-scholes-formula/
     * @notice ONLY used when spot oracle is denominated in USDC
     * @param st is the strike price of the option
     * @param expiryTimestamp is the unix timestamp of expiry
     * @return delta for given option. 4 decimals (ex: 8100 = 0.81 delta) as this is what strike selection
     * module recognizes
     */
    function getOptionDelta(uint256 st, uint256 expiryTimestamp)
        external
        view
        returns (uint256 delta)
    {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        uint256 spotPrice = priceOracle.latestAnswer();
        (uint256 sp, uint256 v, ) = blackScholesParams(
            spotPrice,
            expiryTimestamp
        );

        delta = _getOptionDelta(sp, st, v, expiryTimestamp);
    }

    /**
     * @notice Calculates the option's delta
     * Formula reference: `d_1` in https://www.investopedia.com/terms/b/blackscholes.asp
     * http://www.optiontradingpedia.com/options_delta.htm
     * https://www.macroption.com/black-scholes-formula/
     * @param sp is the spot price of the option
     * @param st is the strike price of the option
     * @param v is the annualized volatility of the underlying asset
     * @param expiryTimestamp is the unix timestamp of expiry
     * @return delta for given option. 4 decimals (ex: 8100 = 0.81 delta) as this is what strike selection
     * module recognizes
     */
    function getOptionDelta(
        uint256 sp,
        uint256 st,
        uint256 v,
        uint256 expiryTimestamp
    ) external view returns (uint256 delta) {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        delta = _getOptionDelta(sp, st, v, expiryTimestamp);
    }

    /**
     * @notice Internal function to calculate the option's delta
     * @param st is the strike price of the option
     * @param expiryTimestamp is the unix timestamp of expiry
     * @return delta for given option. 4 decimals (ex: 8100 = 0.81 delta) as this is what strike selection
     * module recognizes
     */
    function _getOptionDelta(
        uint256 sp,
        uint256 st,
        uint256 v,
        uint256 expiryTimestamp
    ) internal view returns (uint256 delta) {
        // days until expiry
        uint256 t = (expiryTimestamp - block.timestamp) / (1 days);

        uint256 d1;
        uint256 d2;

        // Divide delta by 10 ** 10 to bring it to 4 decimals for strike selection
        if (sp >= st) {
            (d1, d2) = derivatives(t, v, sp, st);
            delta = Math.ncdf((Math.FIXED_1 * d1) / 1e18) / (10**10);
        } else {
            // If underlying < strike price notice we switch st <-> sp passed into d
            (d1, d2) = derivatives(t, v, st, sp);
            delta =
                uint256(10) *
                (10**13) -
                (Math.ncdf((Math.FIXED_1 * d2) / 1e18)) /
                (10**10);
        }
    }

    /**
     * @notice Calculates black scholes for both put and call
     * @param t is the days until expiry
     * @param v is the annualized volatility
     * @param sp is the underlying price
     * @param st is the strike price
     * @return call is the premium of the call option given parameters
     * @return put is the premium of the put option given parameters
     */
    function quoteAll(
        uint256 t,
        uint256 v,
        uint256 sp,
        uint256 st
    ) private view returns (uint256 call, uint256 put) {
        uint256 _c;
        uint256 _p;

        if (sp > st) {
            _c = blackScholes(t, v, sp, st);
            _p = DSMath.max(_c + st, sp) == sp ? 0 : _c + st - sp;
        } else {
            _p = blackScholes(t, v, st, sp);
            _c = DSMath.max(_p + sp, st) == st ? 0 : _p + sp - st;
        }

        return (_c, _p);
    }

    /**
     * @notice Calculates black scholes for the ITM option at mint given strike
     * price and underlying given the parameters (if underling >= strike price this is
     * premium of call, and put otherwise)
     * @param t is the days until expiry
     * @param v is the annualized volatility
     * @param sp is the underlying price
     * @param st is the strike price
     * @return premium is the premium of option
     */
    function blackScholes(
        uint256 t,
        uint256 v,
        uint256 sp,
        uint256 st
    ) private view returns (uint256 premium) {
        console.logUint(t);
        console.logUint(v);
        console.logUint(sp);
        console.logUint(st);

        (uint256 d1, uint256 d2) = derivatives(t, v, sp, st);
        console.logUint(d1);
        console.logUint(d2);

        console.log("Before using cdf & ncdf");
        console.logUint((Math.FIXED_1 * d1) / 1e18);
        console.logInt((int256(Math.FIXED_1) * int256(d2)) / 1e18);

        uint256 cdfD1 = Math.ncdf((Math.FIXED_1 * d1) / 1e18);
        uint256 cdfD2 = Math.cdf((int256(Math.FIXED_1) * int256(d2)) / 1e18);
        console.logUint(cdfD1);
        console.logUint(cdfD2);

        premium = (sp * cdfD1) / 1e14 - (st * cdfD2) / 1e14;
    }

    /**
     * @notice Calculates d1 and d2 used in black scholes calculation
     * as parameters to black scholes calculations
     * @param t is the days until expiry
     * @param v is the annualized volatility
     * @param sp is the underlying price
     * @param st is the strike price
     * @return d1 and d2
     */
    function derivatives(
        uint256 t,
        uint256 v,
        uint256 sp,
        uint256 st
    ) internal pure returns (uint256 d1, uint256 d2) {
        require(sp > 0, "!sp");
        require(st > 0, "!st");

        uint256 sigma = ((v**2) / 2);
        uint256 sigmaB = 1e36;

        uint256 sig = (((1e18 * sigma) / sigmaB) * t) / 365;

        uint256 sSQRT = (v * Math.sqrt2((1e18 * t) / 365)) / 1e9;
        require(sSQRT > 0, "!sSQRT");

        d1 = (1e18 * Math.ln((Math.FIXED_1 * sp) / st)) / Math.FIXED_1;
        d1 = ((d1 + sig) * 1e18) / sSQRT;
        d2 = d1 - sSQRT;
    }

    /**
     * @notice Calculates the current underlying price, annualized volatility, and days until expiry
     * as parameters to black scholes calculations
     * @param expiryTimestamp is the unix timestamp of expiry
     * @return sp is the underlying
     * @return v is the volatility
     * @return t is the days until expiry
     */
    function blackScholesParams(uint256 spotPrice, uint256 expiryTimestamp)
        private
        view
        returns (
            uint256 sp,
            uint256 v,
            uint256 t
        )
    {
        // chainlink oracle returns crypto / usd pairs with 8 decimals, like otoken strike price
        sp = (spotPrice * (10**8)) / (10**_priceOracleDecimals);
        // annualized vol * 10 ** 8 because delta expects 18 decimals
        // and annualizedVol is 8 decimals
        v = volatilityOracle.annualizedVol(optionId) * (10**10);
        t = (expiryTimestamp - block.timestamp) / (1 days);
        console.log("Volatility");
        console.logUint(v);
    }

    /**
     * @notice Calculates the underlying assets price
     */
    function getUnderlyingPrice() external view returns (uint256 price) {
        price = priceOracle.latestAnswer();
    }
}
