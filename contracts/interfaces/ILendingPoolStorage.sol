// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
  * @title ILendingPoolStorage
  * @notice Defines the interface for Lending Pool Storage of Par4 protocol.
*/

interface ILendingPoolStorage {

  /**
    * @notice Emitted on addLendingToken()
    * @param newLendingToken The address of the new token added as a lending asset.
  */
  event LendingTokenAdded(
    address newLendingToken
  );

  /**
    * @notice Emitted on addCollateralToken()
    * @param newCollateralToken The address of the new token added as collateral.
  */
  event CollateralTokenAdded(
    address newCollateralToken
  );
  
  /**
    * @notice Adds a new token to the list of approved lending assets, leading to LendingTokenAdded event.
    *         This allows the token to be supplied and borrowed within the protocol.
    * @param newLendingToken The address of the token to be added as a lending asset.
  */
  function addLendingToken(
    address newLendingToken
  ) external;

  /**
    * @notice Adds a new token to the list of approved collateral assets, leading to CollateralTokenAdded event.
    *         This allows the token to be used as collateral in the protocol.
    * @param newCollateralToken The address of the token to be added as collateral.
  */
  function addCollateralToken(
    address newCollateralToken
  ) external;

  /**
    * @dev Calculate the total debt of a user across all lending tokens.
    * @param user The address of the user whose total debt is being calculated.
    * @return The total debt of the user in terms of the borrowed amount.
  */
  function getUserTotalDebt(
    address user
  ) external returns (uint256);
}