// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "hardhat/console.sol";
import "./libs/ABDKMathQuad.sol";
import "./libs/ABDKMath64x64.sol";
import "./libs/Math.sol";
import "./libs/GaussianCDF.sol";

contract TestingMathLib {
    using SafeCast for uint256;

    uint256 internal constant FIXED_1 = 0x080000000000000000000000000000000;

    function optimalExp(uint256 x) internal view returns (uint256) {
        uint256 res = 0;
        uint256 y;
        uint256 z;
        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        console.logUint(res);
        z = (z * y) / FIXED_1;
        console.logUint(z);
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        console.logUint(res);
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!
        console.logUint(res);

        if ((x & 0x010000000000000000000000000000000) != 0)
            res =
                (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) /
                0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        console.logUint(res);

        if ((x & 0x020000000000000000000000000000000) != 0)
            res =
                (res * 0x18ebef9eac820ae8682b9793ac6d1e778) /
                0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        console.logUint(res);

        if ((x & 0x040000000000000000000000000000000) != 0)
            res =
                (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) /
                0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        console.logUint(res);

        if ((x & 0x080000000000000000000000000000000) != 0)
            res =
                (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) /
                0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        console.logUint(res);

        if ((x & 0x100000000000000000000000000000000) != 0)
            res =
                (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) /
                0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        console.logUint(res);

        if ((x & 0x200000000000000000000000000000000) != 0)
            res =
                (res * 0x00960aadc109e7a3bf4578099615711d7) /
                0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        console.logUint(res);

        if ((x & 0x400000000000000000000000000000000) != 0)
            res =
                (res * 0x0002bf84208204f5977f9a8cf01fdc307) /
                0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)
        console.logUint(res);

        return res;
    }

    function getNum(int128 x) external pure returns (int64) {
        return ABDKMath64x64.toInt(x);
    }

    function getExp(uint256 x) external view returns (bytes16) {
        uint128 x1 = x.toUint128();
        bytes16 val1 = bytes16(x1);
        console.logUint(x1);
        console.logBytes16(val1);
        return ABDKMathQuad.exp(val1);
    }

    function getOptimalExp(uint256 x) external view returns (uint256) {
        return optimalExp(x);
    }

    function getCDF(int256 x) external pure returns (uint256) {
        return Math.cdf(x);
    }

    function getNCDF(uint256 x) external pure returns (uint256) {
        return Math.ncdf(x);
    }
}
