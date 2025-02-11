// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { PriceOracle } from "../utils/PriceOracle.sol";
import { LendingPool } from "./LendingPool.sol";
import { IERC20 } from "../dependencies/openzeppelin/contracts/IERC20.sol";

contract CollateralManager {
  PriceOracle public priceOracle;
  address public lendingPool;

  mapping(address => mapping(address => uint256)) public userCollateral; // user -> token -> amount
  address[] public collateralTokens;

  event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
  event CollateralWithdrawn(address indexed user, address indexed token, uint256 amount);
  event Liquidated(address indexed user, address indexed token, uint256 amount);

  constructor(address _priceOracle) {
    priceOracle = PriceOracle(_priceOracle);
    lendingPool = msg.sender; // LendingPool deploys this contract
  }

  modifier onlyLendingPool() {
    require(msg.sender == lendingPool, "Only LendingPool can call this function");
    _;
  }

  function deposit(address user, address token, uint256 amount) external onlyLendingPool {
    require(priceOracle.getPrice(token) > 0, "Unsupported collateral");
    userCollateral[user][token] += amount;
    emit CollateralDeposited(user, token, amount);
  }

  function withdraw(address token, uint256 amount) external {
    require(userCollateral[msg.sender][token] >= amount, "Insufficient collateral");
    uint256 remainingValue = getCollateralValue(msg.sender) - priceOracle.getPrice(token) * amount;
    require(remainingValue >= getLoanValue(msg.sender) * 125 / 100, "Collateral below required threshold");

    userCollateral[msg.sender][token] -= amount;
    IERC20(token).transfer(msg.sender, amount);
    emit CollateralWithdrawn(msg.sender, token, amount);
  }

  function getCollateralValue(address user) public view returns (uint256) {
    uint256 totalValue = 0;
    for (uint256 i = 0; i < collateralTokens.length; i++) {
      address token = collateralTokens[i];
      totalValue += priceOracle.getPrice(token) * userCollateral[user][token];
    }
    return totalValue;
  }

  function getBorrowLimit(address user) external view returns (uint256) {
    return (getCollateralValue(user) * 75) / 100; // 75% Loan-to-Value (LTV) ratio
  }

  function isLiquidatable(address user) external view returns (bool) {
    return getCollateralValue(user) < getLoanValue(user) * 125 / 100;
  }

  function liquidate(address user, address token, uint256 amount) external onlyLendingPool {
    require(getCollateralValue(user) < getLoanValue(user) * 125 / 100, "Not liquidatable");

    userCollateral[user][token] -= amount;
    IERC20(token).transfer(msg.sender, amount);
    emit Liquidated(user, token, amount);
  }

  function getLoanValue(address user) internal view returns (uint256) {
    return LendingPool(lendingPool).getUserTotalDebt(user);
  }
}
