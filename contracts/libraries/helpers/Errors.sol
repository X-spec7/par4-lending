// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
  * @title Errors Library
  * @notice A centralized library of error messages used across the protocol.
*/
library Errors {
  
  /// @notice Thrown when the caller is not an admin.
  string public constant CALLER_NOT_ADMIN = "Caller is not admin";
  
  /// @notice Thrown when the collateral token has already been added to the system.
  string public constant COLLATERAL_ALREADY_ADDED = "Collateral already added";
  
  /// @notice Thrown when the lending token has already been added to the system.
  string public constant LENDING_TOKEN_ALREADY_ADDED = "Lending token already added";

  /// @notice Thrown when an unsupported lending token is used.
  string public constant UNSUPPORTED_LENDING_TOKEN = "Lending token not supported";
  
  /// @notice Thrown when an unsupported collateral token is used.
  string public constant UNSUPPORTED_COLLATERAL = "Collateral not supported";
  
  /// @notice Thrown when there is insufficient liquidity available from the lender.
  string public constant INSUFFICIENT_LENDER_LIQUIDITY = "Insufficient lender liquidity";
  
  /// @notice Thrown when the borrowing limit is exceeded.
  string public constant EXCEED_BORROWING_LIMIT = "Exceeds borrowing limit";
  
  /// @notice Thrown when there is no active loan to perform the requested operation.
  string public constant NO_ACTIVE_LOAN = "No active loan";
  
  /// @notice Thrown when the position is not eligible for liquidation.
  string public constant NOT_LIQUIDATABLE = "LTV does not exceed the threshold";
}
