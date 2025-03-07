// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../helpers/Errors.sol";

/**
 * @title Parf Math Contract
 * @dev Safe math functions for type casting
 */
contract ParfMath {
    function safe64(uint n) internal pure returns (uint64) {
        if (n > type(uint64).max) revert(Errors.INVALID_UINT64);
        return uint64(n);
    }

    function safe104(uint n) internal pure returns (uint104) {
        if (n > type(uint104).max) revert(Errors.INVALID_UINT104);
        return uint104(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert(Errors.INVALID_UINT128);
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        if (n > uint104(type(int104).max)) revert(Errors.INVALID_INT104);
        return int104(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        if (n > uint256(type(int256).max)) revert(Errors.INVALID_INT256);
        return int256(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        if (n < 0) revert(Errors.NEGATIVE_NUMBER);
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        if (n < 0) revert(Errors.NEGATIVE_NUMBER);
        return uint256(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}
