// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InterestRateModel {
  uint256 public baseRate; // Base interest rate (e.g., 2%)
  uint256 public utilizationMultiplier; // Multiplier for interest rate (e.g., 20%)

  constructor(uint256 _baseRate, uint256 _utilizationMultiplier) {
    baseRate = _baseRate;
    utilizationMultiplier = _utilizationMultiplier;
  }

  function calculateInterestRate(address token, uint256 borrowedAmount, uint256 totalLiquidity) external view returns (uint256) {
    if (totalLiquidity == 0) {
      return baseRate;
    }
    uint256 utilizationRate = (borrowedAmount * 1e18) / totalLiquidity;
    return baseRate + (utilizationMultiplier * utilizationRate) / 1e18;
  }
}
