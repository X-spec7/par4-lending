// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "../types/DataTypes.sol";

library InterestCalculator {
    /**
     * @notice Calculates the accrued simple interest on a loan based on the time elapsed
     *         since the last payment and an adjustment factor from the pool's utilization rate.
     *         This implements a tiered interest rate based on utilization.
     * @param loan The loan for which to calculate interest.
     * @param utilizationRate The current utilization rate of the pool (e.g., 25 for 25%).
     * @return The accrued interest amount.
     *
     * @dev The interest rate is determined based on the following tiered structure:
     *    Utilization 0-16%  => 6% APR (2% slope)
     *    Utilization 16-32% => 8% APR (4% slope)
     *    Utilization 32-48% => 10% APR (6% slope)
     *    Utilization 48-64% => 12% APR (8% slope)
     *    Utilization 64-100% => 14% APR (10% slope)
     */
    function calculateAccruedInterest(
        DataTypes.Loan storage loan,
        uint256 utilizationRate
    ) internal view returns (uint256) {
        // If there's no principal, there's no interest
        if (loan.principalAmount == 0) {
            return 0;
        }

        // Determine the elapsed time since the last payment (or since the loan start if no payment has been made)
        uint256 elapsedTime = block.timestamp - loan.lastPaymentTimestamp;

        // Determine the borrowing APR based on utilization rate
        uint256 borrowingAPR;

        if (utilizationRate <= 16) {
            borrowingAPR = 6; // 6% APR for utilization rate 0-16%
        } else if (utilizationRate <= 32) {
            borrowingAPR = 8; // 8% APR for utilization rate 16-32%
        } else if (utilizationRate <= 48) {
            borrowingAPR = 10; // 10% APR for utilization rate 32-48%
        } else if (utilizationRate <= 64) {
            borrowingAPR = 12; // 12% APR for utilization rate 48-64%
        } else {
            borrowingAPR = 14; // 14% APR for utilization rate 64-100%
        }

        // Calculate accrued interest using a simple interest formula:
        // accruedInterest = principal * annualInterestRateBasisPoints/10000 * (elapsedTime / 365 days)
        uint256 accruedInterest = (loan.principalAmount *
            borrowingAPR *
            elapsedTime) / (365 days * 100);

        return accruedInterest;
    }
}
