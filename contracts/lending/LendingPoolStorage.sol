// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../dependencies/openzeppelin/contracts/IERC20.sol";
import { ILendingPoolStorage } from "../interfaces/ILendingPoolStorage.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { Errors } from "../libraries/helpers/Errors.sol";
import { DataTypes } from "../libraries/types/DataTypes.sol";
import { InterestCalculator } from "../libraries/helpers/InterestCalculator.sol";

/**
  * @title LendingPoolStorage
  * @notice This contract stores the data related to loans, collateral, and lending tokens. 
  *         It is primarily used by the LendingPool to interact with and manage users' loans and collateral.
*/
abstract contract LendingPoolStorage is ILendingPoolStorage {
  using InterestCalculator for DataTypes.Loan;

  struct TokenPrice {
    address token;  // The address of the token
    uint256 price;  // The USD price of the token
  }

  uint256 loanId = 0;

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

  // TODO!: implement debt token for borrowing instead of storing in a map
  mapping(address => DataTypes.Loan[]) public loans; // borrower -> Loan data

  // TODO!: implement pToken for adding liquidity instead of storing in map
  mapping(address => DataTypes.LendingPosition) public userLendingPositions; // user -> LendingPosition

  mapping(address => mapping(address => uint256)) public userCollateral; // user -> token -> amount

  mapping(address => DataTypes.PoolTokenState) public poolTokenStates; // token -> PoolTokenState

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
    DataTypes.Loan[] storage userLoans = loans[user];
    uint256 totalDebt = 0;

    uint256 tokenCount = 0;
    TokenPrice[] memory tokenPrices = new TokenPrice[](userLoans.length);

    uint256 tokenPrice;
    bool found = false;
    
    for (uint256 i = 0; i < userLoans.length; i++) {
      DataTypes.Loan storage loan = userLoans[i];
      
      // Skip loans that have a zero principal (e.g., if they've been repaid or are inactive)
      if (loan.principalAmount == 0) {
        continue;
      }

      // Search for token price in memory array (small lookup overhead)
      for (uint256 j = 0; j < tokenCount; j++) {
        if (tokenPrices[j].token == loan.principalToken) {
          tokenPrice = tokenPrices[j].price;
          found = true;
          break;
        }
      }

      // Fetch price only once per token
      if (!found) {
        tokenPrice = IPriceOracle(priceOracleAddress).getPrice(loan.principalToken);
        tokenPrices[tokenCount] = TokenPrice(loan.principalToken, tokenPrice);
        tokenCount++;
      }

      uint256 accruedInterest = loan.calculateAccruedInterest(getUtilizationRate(loan.principalToken));

      totalDebt += (loan.principalAmount + accruedInterest) * tokenPrice;
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

  /// @inheritdoc ILendingPoolStorage
  function getUtilizationRate(
    address token
  ) public view override returns (uint256) {
    DataTypes.PoolTokenState storage tokenState = poolTokenStates[token];

    uint256 utilizationRate = (tokenState.grossLiquidity - tokenState.availableLiquidity) / tokenState.grossLiquidity;

    return utilizationRate;
  }
}
