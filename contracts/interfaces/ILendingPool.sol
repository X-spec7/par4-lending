// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
  * @title ILendingPool
  * @notice Defines the interface for Lending Pool of Par4 protocol.
 */

interface ILendingPool {
  /**
    * @dev Emitted on supply()
    * @param lender The address of the lender who is adding liquidity to the pool
    * @param token The address of the lending asset
    * @param amount The amount of asset being supplied
  */
  event AssetSupplied(
    address indexed lender,
    address indexed token,
    uint256 amount
  );

  /**
    * @dev Emitted on lenderWithdraw()
    * @param lender The address of the lender withdrawing the supply
    * @param token The address of the lending asset
    * @param amount The amount for lending asset being withdrawn
  */
  event AssetWithdrawn(
    address indexed lender,
    address indexed token,
    uint256 amount
  );
  
  /**
    * @dev Emitted on depositCollateral()
    * @param user The address of the user depositing collateral
    * @param token The address of the deposited collateral asset
    * @param amount The amount of supplied collateral asset
  */
  event CollateralDeposited(
    address indexed user,
    address indexed token,
    uint256 amount
  );

  /// @notice Emitted on withdrawCollateral().
  /// @param user The address of the user who withdrew the collateral.
  /// @param token The address of the collateral token that was withdrawn.
  /// @param amount The amount of collateral that was withdrawn.
  event CollateralWithdrawn(
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
  event LoanRepayed(
    address indexed user,
    address indexed token,
    uint256 amount
  );

  /**
    * @dev Emitted on liquidate()
    * @param user The address of the user whose collateral is being liquidated
  */
  event EntireCollateralLiquidated(
    address indexed user,
  );

  /**
    * @notice Supplies certain amount of underlying asset into the Lending Pool,
    *         leading to a AssetSupplied event.
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
    *         leading to AssetWithdrawn event.
    * @param asset The address of the asset being withdrawn
    * @param amount The amount of the asset being withdrawn
  */
  function lenderWithdraw(
    address asset,
    uint256 amount
  ) external;

  /**
    * @notice deposit collateral to the pool,
    *         leading to CollateralDeposited event.
    * @param collateral The address of the collateral asset being depoisted
    * @param amount The amount of the collateral asset being depoisted
  */
  function depositCollateral(
    address collateral,
    uint256 amount
  ) external;

  /// @notice Withdraws a specified amount of collateral from the protocol.
  /// @dev This function allows a user to remove collateral that they've supplied.
  /// @param collateral The address of the collateral token to withdraw.
  /// @param amount The amount of collateral to be withdrawn.
  function withdrawCollateral(
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
    *         leading to LoanRepayed event.
    * @param asset The address of the lending asset being repayed
    * @param amount The amount of the lending asset being repayed
  */
  function repayLoan(
    address asset,
    uint256 amount
  ) external;

  /**
    * @notice Liquidate the whole collateral assets of a user when the Loan-to-Value (LTV) ratio 
    *         exceeds the allowed threshold, leading to a EntireCollateralLiquidated event.
    * @param user The address of the borrower whose collateral is being liquidated
  */
  function liquidate(
    address user
  ) external;
}
