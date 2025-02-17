// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../dependencies/openzeppelin/contracts/IERC20.sol";
import { ILendingPoolStorage } from "../interfaces/ILendingPoolStorage.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { Errors } from "../libraries/helpers/Errors.sol";

/**
  * @title LendingPoolStorage
  * @notice This contract stores the data related to loans, collateral, and lending tokens. 
  *         It is primarily used by the LendingPool to interact with and manage users' loans and collateral.
*/
contract LendingPoolStorage is ILendingPoolStorage {
  
  /**
    * @dev Loan struct represents the details of a user's loan.
    * @param amount The borrowed amount of the lending token
    * @param collateralAmount The value of collateral provided by the borrower
    * @param interestRate The interest rate applied to the loan
    * @param lastUpdated The timestamp of the last update to the loan
  */

  struct Loan {
    uint256 amount;
    uint256 collateralAmount;
    uint256 interestRate;
    uint256 lastUpdated;
  }

  // The address of the LendingPool contract
  address public lendingPool;
  // The address of the treasury where collected fees are stored
  address public treasury;
  // The address of the price oracle used to get token prices
  address public priceOracleAddress;

  // Mappings to check if a token is accepted as collateral or a lending token
  mapping(address => bool) public isCollateral;
  mapping(address => bool) public isLendingToken;
  
  // Arrays to store the lists of collateral and lending tokens
  address[] public lendingTokens;
  address[] public collateralTokens;

  // TODO!: implement debt token for borrowing instead of storing just in a mapping
  mapping(address => mapping(address => Loan)) public loans; // borrower -> token -> Loan data

  // TODO!: implement pToken for adding liquidity instead of storing just in mapping
  mapping(address => mapping(address => uint256)) public userCollateral; // user -> token -> amount
  mapping(address => mapping(address => uint256)) public userLiquidity; // user -> token -> amount

  /// @inheritdoc ILendingPoolStorage
  function addCollateralToken(address token) external {
    require(!isCollateral[token], Errors.COLLATERAL_ALREADY_ADDED);
    isCollateral[token] = true;
    collateralTokens.push(token);
    emit LendingTokenAdded(token);
  }

  /// @inheritdoc ILendingPoolStorage
  function addLendingToken(address token) external {
    require(!isLendingToken[token], Errors.LENDING_TOKEN_ALREADY_ADDED);
    isLendingToken[token] = true;
    lendingTokens.push(token);
    emit CollateralTokenAdded(token);
  }

  /// @inheritdoc ILendingPoolStorage
  function getUserTotalDebt(
    address user
  ) public view override returns (uint256) {
    uint256 totalDebt = 0;
    // Iterate through all lending tokens and sum the user's loan amounts
    for (uint256 i = 0; i < lendingTokens.length; i++) {
      address token = lendingTokens[i];
      totalDebt += loans[user][token].amount;
    }
    return totalDebt;
  }

  /// @inheritdoc ILendingPoolStorage
  function getUserCollateralValue(
    address user
  ) public view override returns (uint256) {
    uint256 totalValue = 0;
    for (uint256 i = 0; i < collateralTokens.length; i++) {
      address token = collateralTokens[i];
      IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
      totalValue += priceOracle.getPrice(token) * userCollateral[user][token];
    }
    return totalValue;
  }

  /// @inheritdoc ILendingPoolStorage
  function getBorrowLimit(
    address user
  ) public view override returns (uint256) {
    return (getUserCollateralValue(user) * 75) / 100; // 75% Loan-to-Value (LTV) ratio
  }

  /// @inheritdoc ILendingPoolStorage
  function isLiquidatable(
    address user
  ) public view override returns (bool) {
    return getUserCollateralValue(user) < getUserTotalDebt(user) * 125 / 100;
  }
}
