// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IParfCore {
    /**
     * @dev Calculate the total debt of a user across all lending tokens.
     * @param user The address of the user whose total debt is being calculated.
     * @return uint256 The total debt of the user in terms of the borrowed amount.
     */
    function getUserTotalDebt(address user) external returns (uint256);

    /**
     * @dev Calculate the total collateral value of a user across all collateral tokens.
     * @param user The address of the user whose total collateral value is being calculated.
     * @return uint256 The calculated total collateral value
     */
    function getUserCollateralValue(address user) external returns (uint256);

    /**
     * @dev Get the limit for borrowing for a user by calculating his collateral value with LTV limit
     * @param user The address of the user whose borrow limit is being calculated
     * @return uint256 The limit for the user to borrow based on his collateral value
     */
    function getBorrowLimit(address user) external returns (uint256);

    /**
     * @dev Check if the LTV of a user exceeds the LTV threshold
     * @param user The address of the user whose LTV is being compared to the LTV threshold
     * @return bool The flag whether the LTV exceeds the threshold or not, true for exceeding, false for not exceeding
     */
    function isLiquidatable(address user) external returns (bool);

    /**
     * @notice Calculates the utilization rate of base asset in the lending pool.
     * @dev Utilization rate is calculated as (borrowed amount / total liquidity).
     * @return The utilization rate as a percentage (scaled by a factor, e.g., in basis points or 1e18 format).
     */
    function getUtilizationRate() external returns (uint256);
}
