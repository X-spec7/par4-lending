// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Errors Library
 * @notice A centralized library of error messages used across the protocol.
 * @dev Standardized error messages improve gas efficiency and code readability.
 */
library Errors {
    /// @notice Thrown when the caller is not authorized to perform an action.
    string public constant CALLER_NOT_ADMIN = "Caller is not an admin";

    /// @notice Thrown when attempting to add a collateral token that already exists.
    string public constant COLLATERAL_ALREADY_ADDED =
        "Collateral already added";

    /// @notice Thrown when attempting to add a lending token that already exists.
    string public constant LENDING_TOKEN_ALREADY_ADDED =
        "Lending token already added";

    /// @notice Thrown when the provided lending token is not supported by the protocol.
    string public constant UNSUPPORTED_LENDING_TOKEN =
        "Unsupported lending token";

    /// @notice Thrown when the provided collateral token is not supported by the protocol.
    string public constant UNSUPPORTED_COLLATERAL =
        "Unsupported collateral token";

    /// @notice Thrown when the lender does not have enough liquidity to fulfill a request.
    string public constant INSUFFICIENT_LENDER_LIQUIDITY =
        "Insufficient lender liquidity";

    /// @notice Thrown when a borrower tries to borrow more than their limit.
    string public constant EXCEED_BORROWING_LIMIT =
        "Borrow amount exceeds limit";

    /// @notice Thrown when a user attempts to perform an operation on a non-existent loan.
    string public constant NO_ACTIVE_LOAN = "No active loan found";

    /// @notice Thrown when a position is not eligible for liquidation due to LTV not exceeding the threshold.
    string public constant NOT_LIQUIDATABLE =
        "Position is not liquidatable (LTV too low)";

    /// @notice Thrown when there is insufficient liquidity available in the pool to fulfill a loan request.
    string public constant INSUFFICIENT_LIQUIDITY =
        "Not enough liquidity in the pool";

    /// @notice Thrown when a repayment amount is less than the required due amount.
    string public constant INSUFFICIENT_REPAYMENT =
        "Repayment amount is insufficient";

    /// @notice Thrown when a number exceeds the maximum value of uint64.
    string public constant INVALID_UINT64 = "Number exceeds uint64 maximum";

    /// @notice Thrown when a number exceeds the maximum value of uint104.
    string public constant INVALID_UINT104 = "Number exceeds uint104 maximum";

    /// @notice Thrown when a number exceeds the maximum value of uint128.
    string public constant INVALID_UINT128 = "Number exceeds uint128 maximum";

    /// @notice Thrown when a number exceeds the maximum value of int104.
    string public constant INVALID_INT104 = "Number exceeds int104 maximum";

    /// @notice Thrown when a number exceeds the maximum value of int256.
    string public constant INVALID_INT256 = "Number exceeds int256 maximum";

    /// @notice Thrown when attempting to convert a negative number to an unsigned type.
    string public constant NEGATIVE_NUMBER = "Cannot convert negative number to unsigned";

    /// @notice Error message thrown when a reentrant call is detected
    string public constant REENTRANT_CALL_BLOCKED = "Cannot re-enter function";
}
