// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ParfStorage.sol";
import "../interfaces/IParfCore.sol";

abstract contract ParfCore is IParfCore, ParfStorage {
    using InterestCalculator for DataTypes.Loan;

    /// @dev The storage slot for storing reentrancy guard flag
    bytes32 internal constant REENTRANCY_GUARD_FLAG_SLOT =
        bytes32(keccak256("parf.reentrancy.guard"));
    
    /// @dev The storage slot for storing treasury address
    bytes32 internal constant TREASURY_ADDRESS_SLOT =
        bytes32(keccak256("parf.treasure.address"));

    /// @dev Reentrancy guard flag statuses
    /// @dev The value `0` indicates that the function has **not** been entered yet. This is the default initial value of the storage slot.
    /// @dev The value `1` indicates that the function has been **entered**, blocking reentrancy.
    uint256 internal constant REENTRANCY_GUARD_NOT_ENTERED = 0;
    uint256 internal constant REENTRANCY_GUARD_ENTERED = 1;

    /**
     * @dev Prevents marked functions from being reentered 
     * Note: this restrict contracts from calling comet functions in their hooks.
     * Doing so will cause the transaction to revert.
     */
    modifier nonReentrant() {
        nonReentrantBefore();
        _;
        nonReentrantAfter();
    }

    /**
     * @dev Checks that the reentrancy flag is not set and then sets the flag
     */
    function nonReentrantBefore() internal {
        bytes32 slot = REENTRANCY_GUARD_FLAG_SLOT;
        uint256 status;
        assembly ("memory-safe") {
            status := sload(slot)
        }

        if (status == REENTRANCY_GUARD_ENTERED) revert (Errors.REENTRANT_CALL_BLOCKED);
        assembly ("memory-safe") {
            sstore(slot, REENTRANCY_GUARD_ENTERED)
        }
    }

    /**
     * @dev Unsets the reentrancy flag
     */
    function nonReentrantAfter() internal {
        bytes32 slot = REENTRANCY_GUARD_FLAG_SLOT;
        assembly ("memory-safe") {
            sstore(slot, REENTRANCY_GUARD_NOT_ENTERED)
        }
    }

    /// @inheritdoc IParfCore
    function getUserTotalDebt(
        address user
    ) public view override returns (uint256) {
        DataTypes.Loan[] storage userLoans = loans[user];
        uint256 totalDebt = 0;

        uint256 tokenCount = 0;
        DataTypes.TokenPrice[] memory tokenPrices = new DataTypes.TokenPrice[](
            userLoans.length
        );

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
                tokenPrice = IPriceOracle(priceOracleAddress).getPrice(
                    loan.principalToken
                );
                tokenPrices[tokenCount] = DataTypes.TokenPrice(
                    loan.principalToken,
                    tokenPrice
                );
                tokenCount++;
            }

            uint256 utilizationRate = getUtilizationRate();

            uint256 accruedInterest = loan.calculateAccruedInterest(
                utilizationRate
            );

            totalDebt += (loan.principalAmount + accruedInterest) * tokenPrice;
        }

        return totalDebt;
    }

    /// @inheritdoc IParfCore
    function getUserCollateralValue(
        address user
    ) public view override returns (uint256) {
        uint256 totalValue = 0;

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            address token = collateralTokens[i];
            IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
            totalValue +=
                priceOracle.getPrice(token) *
                userCollaterals[user][token];
        }

        return totalValue;
    }

    /// @inheritdoc IParfCore
    function getBorrowLimit(
        address user
    ) public view override returns (uint256) {
        return (getUserCollateralValue(user) * 75) / 100; // 75% Loan-to-Value (LTV) ratio
    }

    /// @inheritdoc IParfCore
    function isLiquidatable(address user) public view override returns (bool) {
        return
            getUserCollateralValue(user) < (getUserTotalDebt(user) * 125) / 100;
    }

    /// @inheritdoc IParfCore
    function getUtilizationRate() public view override returns (uint256) {
        uint256 utilizationRate = borrowBase / supplyBase;

        return utilizationRate;
    }
}
