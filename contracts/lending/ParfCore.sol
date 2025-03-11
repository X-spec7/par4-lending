// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ParfStorage.sol";

abstract contract ParfCore is ParfStorage {
    /// @dev The storage slot for storing reentrancy guard flag
    bytes32 internal constant REENTRANCY_GUARD_FLAG_SLOT =
        bytes32(keccak256("parf.reentrancy.guard"));

    /// @dev Reentrancy guard flag statuses
    /// @dev The value `0` indicates that the function has **not** been entered yet. This is the default initial value of the storage slot.
    /// @dev The value `1` indicates that the function has been **entered**, blocking reentrancy.
    uint256 internal constant REENTRANCY_GUARD_NOT_ENTERED = 0;
    uint256 internal constant REENTRANCY_GUARD_ENTERED = 1;
}
