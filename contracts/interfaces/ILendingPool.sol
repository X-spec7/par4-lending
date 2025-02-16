// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
  * @title ILendingPool
  * @notice Defines the interface for Lending Pool of Par4 protocol.
 */

interface ILendingPool {
  /**
    * @dev Emitted on depositCollateral()
    * @param user The address of the user depositing collateral
    * @param token The address of the deposited collateral asset
    * @param amount The amount of supplied collateral asset
  */
  event DepositCollateral(
    address indexed user,
    address indexed token,
    uint256 amount
  );

  /**
    * @dev Emitted on borrow()
    * @param user The address of the borrower
    * @param token The address of the token being borrowed
    * @param collateralAmount The amount of collateral value of the user
  */
  event Borrow(
    address indexed user,
    address indexed token,
    uint256 amount,
    uint256 collateralAmount
  );

  /**
    * @dev Emitted on repayLoan()
    * @param user The address of the user who is repaying loan
    * @param token The address of the lending token being repayed
    * @param amount The amount of asset being repayed
  */
  event LoanRepay(
    address indexed user,
    address indexed token,
    uint256 amount
  );

  /**
    * @dev Emitted on liquidate()
    * @param user The address of the user whose collateral is being liquidated
    * @param token The address of the collateral token which is being liquidated
    * @param amount The amount of collateral being liquidated
  */
  event Liquidation(
    address indexed user,
    address indexed token,
    uint256 amount
  );

  /**
    * @dev Emitted on supply()
    * @param lender The address of the lender who is adding liquidity to the pool
    * @param token The address of the lending asset
    * @param amount The amount of asset being supplied
  */
  event Supply(
    address indexed lender,
    address indexed token,
    uint256 amount
  );

  /**
    * @dev Emitted on lenderWithdraw()
    * @param lender The address of the lender withdrawing the supply
    * @param token The address of the lending asset
    * @param amount The amount for lending asset being withdrawed
  */
  event LenderWithdraw(
    address indexed lender,
    address indexed token,
    uint256 amount
  );

  /**
    * @notice Emitted on addLendingToken()
    * @param newLendingToken The address of the new token added as a lending asset.
  */
  event AddLendingToken(
    address newLendingToken
  );

  /**
    * @notice Emitted on addCollateralToken()
    * @param newCollateralToken The address of the new token added as collateral.
  */
  event AddCollateralToken(
    address newCollateralToken
  );

  /**
    * @notice Supplies certain amount of underlying asset into the Lending Pool,
    *         leading to a Supply event.
    * - Currently it is not mint any token to the supplier which must be implemented later.
    * @param asset The address of the asset being supplied
    * @param amount The amount of the asset being supplied
  */
  function supply(
    address asset,
    uint256 amount
  ) external;

  /**
    * @notice withdraw the lended token from the pool,
    *         leading to RenderWithdraw event.
    * @param asset The address of the asset being withdrawed
    * @param amount The amount of the asset being withdrawed
  */
  function renderWithdraw(
    address asset,
    uint256 amount
  ) external;

  /**
    * @notice deposit collateral to the pool,
    *         leading to DepositCollateral event.
    * @param collateral The address of the collateral asset being depoisted
    * @param amount The amount of the collateral asset being depoisted
  */
  function depositCollateral(
    address collateral,
    uint256 amount
  ) external;

  /**
    * @notice borrow lending token,
    *         leading to Borrow event
    * - Currently it doesn't mint any Loan token, which must be included later.
    * @param asset The address of the asset being borrowed
    * @param amount The amount of the asset being borrowed
  */
  function borrow(
    address asset,
    uint256 amount
  ) external;

  /**
    * @notice repay the loan,
    *         leading to RepayLoan event.
    * @param asset The address of the lending asset being repayed
    * @param amount The amount of the lending asset being repayed
  */
  function repayLoan(
    address asset,
    uint256 amount
  ) external;

  /**
    * @notice Liquidate the collateral asset when the Loan-to-Value (LTV) ratio 
    *         exceeds the allowed threshold, leading to a liquidation event.
    * @param asset The address of the collateral asset being liquidated
    * @param user The address of the borrower whose collateral is being liquidated
  */
  function liquidate(
    address asset,
    address user
  ) external;

  /**
    * @notice Adds a new token to the list of approved lending assets.
    *         This allows the token to be supplied and borrowed within the protocol.
    * @param newLendingToken The address of the token to be added as a lending asset.
  */
  function addLendingToken(
    address newLendingToken
  ) external;

  /**
    * @notice Adds a new token to the list of approved collateral assets.
    *         This allows the token to be used as collateral in the protocol.
    * @param newCollateralToken The address of the token to be added as collateral.
  */
  function addCollateralToken(
    address newCollateralToken
  ) external;
}
