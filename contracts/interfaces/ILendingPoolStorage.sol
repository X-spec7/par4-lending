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
    event LendingTokenAdded(address newLendingToken);

    /**
     * @notice Emitted on addCollateralToken()
     * @param newCollateralToken The address of the new token added as collateral.
     */
    event CollateralTokenAdded(address newCollateralToken);

    /**
     * @notice Adds a new token to the list of approved lending assets, leading to LendingTokenAdded event.
     *         This allows the token to be supplied and borrowed within the protocol.
     * @param newLendingToken The address of the token to be added as a lending asset.
     */
    function addLendingToken(address newLendingToken) external;

    /**
     * @notice Adds a new token to the list of approved collateral assets, leading to CollateralTokenAdded event.
     *         This allows the token to be used as collateral in the protocol.
     * @param newCollateralToken The address of the token to be added as collateral.
     */
    function addCollateralToken(address newCollateralToken) external;

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
     * @notice Calculates the utilization rate of a given token in the lending pool.
     * @dev Utilization rate is calculated as (borrowed amount / total liquidity).
     * @param token The address of the token for which the utilization rate is being calculated.
     * @return The utilization rate as a percentage (scaled by a factor, e.g., in basis points or 1e18 format).
     */
    function getUtilizationRate(address token) external returns (uint256);
}
