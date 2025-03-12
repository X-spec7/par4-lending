// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ReentrancyGuard} from "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";
import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";
import {Initializable} from "../dependencies/openzeppelin/proxy/Initializable.sol";
import {PriceOracle} from "../utils/PriceOracle.sol";
import {ILendingPool} from "../interfaces/IParfPool.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {ParfStorage} from "./ParfStorage.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Helper} from "../libraries/helpers/Helper.sol";
import {InterestCalculator} from "../libraries/helpers/InterestCalculator.sol";
import {ParfCore} from "./ParfCore.sol";

/**
 * @title Par4 Lending Pool Contract
 * @notice Main entry to interact with Par4 protocol
 * - The following actions can be done:
 *   # supply
 *   # withdraw
 *   # deposit collateral
 *   # borrow
 *   # repay
 */
contract ParfPool is
    ILendingPool,
    Ownable,
    Initializable,
    ParfCore
{
    using SafeERC20 for IERC20;
    using InterestCalculator for DataTypes.Loan;

    // Fee structure (39 basis points = 0.39%)
    uint16 public constant FEE_BPS = 39;
    uint16 public constant CASHBACK_BPS = 1500;
    uint16 public constant BPS_DIVISOR = 10000;

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

    function initialize(address _treasury) external initializer {
        priceOracleAddress = address(new PriceOracle());
        treasury = _treasury;
    }

    /// @inheritdoc ILendingPool
    function supply(
        address asset,
        uint256 amount
    ) external virtual override nonReentrant {
        // require(isLendingToken[asset], Errors.UNSUPPORTED_LENDING_TOKEN);

        // // Transfer the asset from the user to the lending pool
        // IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // // Update pool token state
        // DataTypes.PoolTokenState storage tokenState = poolTokenStates[asset];
        // tokenState.grossLiquidity += amount;
        // tokenState.availableLiquidity += amount;

        // // Update user lending position
        // DataTypes.LendingPosition storage position = userLendingPositions[
        //     msg.sender
        // ];
        // if (position.amount == 0) {
        //     position.lender = msg.sender;
        //     position.lendingToken = asset;
        //     position.depositTimestamp = block.timestamp;
        // }
        // position.amount += amount;
        // position.lastActionTimestamp = block.timestamp;

        // Emit event that asset has been supplied
        emit AssetSupplied(msg.sender, asset, amount);
    }

    /// @inheritdoc ILendingPool
    function lenderWithdraw(
        address asset,
        uint256 amount
    ) external virtual override nonReentrant {
        require(isLendingToken[asset], Errors.UNSUPPORTED_LENDING_TOKEN);

        // Check if the user has enough balance to withdraw
        uint256 lenderBalance = IERC20(asset).balanceOf(address(this));
        require(lenderBalance >= amount, Errors.INSUFFICIENT_LENDER_LIQUIDITY);

        uint256 fee = amount * FEE_BPS;

        // Transfer the specified amount back to the lender, fee to treasury address
        IERC20(asset).safeTransfer(msg.sender, amount - fee);
        IERC20(asset).safeTransfer(treasury, fee);

        // Emit event that the asset has been withdrawn by the lender
        emit AssetWithdrawn(msg.sender, asset, amount);
    }

    /// @inheritdoc ILendingPool
    function depositCollateral(
        address collateral,
        uint256 amount
    ) external virtual override nonReentrant {
        require(isCollateral[collateral], Errors.UNSUPPORTED_COLLATERAL);

        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        userCollaterals[msg.sender][collateral] += amount;

        emit CollateralDeposited(msg.sender, collateral, amount);
    }

    /// @inheritdoc ILendingPool
    function withdrawCollateral(
        address collateral,
        uint256 amount
    ) external virtual override nonReentrant {
        require(isCollateral[collateral], Errors.UNSUPPORTED_COLLATERAL);

        IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
        uint256 remainingValue = getUserCollateralValue(msg.sender) -
            priceOracle.getPrice(collateral) *
            amount;
        require(
            remainingValue >= (getUserTotalDebt(msg.sender) * 125) / 100,
            "Collateral below required threshold"
        );

        uint256 fee = (amount * FEE_BPS) / BPS_DIVISOR;

        userCollaterals[msg.sender][collateral] -= amount;
        IERC20(collateral).safeTransfer(msg.sender, amount - fee);
        IERC20(collateral).safeTransfer(treasury, fee);

        emit CollateralWithdrawn(msg.sender, collateral, amount);
    }

    /// @inheritdoc ILendingPool
    function borrow(
        address token,
        uint256 amount,
        DataTypes.LoanTerm selectedTerm
    ) external virtual override nonReentrant {
        require(isLendingToken[token], Errors.UNSUPPORTED_LENDING_TOKEN);

        uint256 maxBorrow = getBorrowLimit(msg.sender);
        require(amount <= maxBorrow, Errors.EXCEED_BORROWING_LIMIT);

        DataTypes.PoolTokenState storage tokenState = poolTokenStates[token];
        require(
            amount <= tokenState.availableLiquidity,
            Errors.INSUFFICIENT_LIQUIDITY
        );

        // Update pool state
        tokenState.availableLiquidity -= amount;

        // Record the loan
        loans[msg.sender].push(
            DataTypes.Loan({
                loanId: loanId,
                borrower: msg.sender,
                principalToken: token,
                principalAmount: amount,
                term: selectedTerm,
                remainingPayments: Helper.calculatePayments(selectedTerm),
                startTimestamp: block.timestamp,
                lastPaymentTimestamp: block.timestamp
            })
        );

        IERC20(token).safeTransfer(msg.sender, amount);

        loanId++;
        emit Borrow(msg.sender, token, amount, selectedTerm);
    }

    /// @inheritdoc ILendingPool
    function repayLoan(
        uint256 loanId,
        uint256 amount
    ) external virtual override nonReentrant {
        DataTypes.Loan[] storage userLoans = loans[msg.sender];
        bool loanFound = false;
        uint256 totalDue = 0;
        uint256 netInterest = 0;
        uint256 pureInterest = 0;
        uint256 cashback = 0;
        uint256 loanIndex = 0;

        for (uint256 i = 0; i < userLoans.length; i++) {
            if (userLoans[i].loanId == loanId) {
                loanFound = true;
                loanIndex = i;

                address token = userLoans[i].principalToken;

                // Calculate interest accrued since last payment
                DataTypes.Loan storage selectedLoan = userLoans[i];

                netInterest = selectedLoan.calculateAccruedInterest(
                    getUtilizationRate(selectedLoan.principalToken)
                );
                cashback = (netInterest * CASHBACK_BPS) / BPS_DIVISOR;
                pureInterest = netInterest - cashback;

                totalDue = selectedLoan.principalAmount + netInterest;

                require(amount >= totalDue, Errors.INSUFFICIENT_REPAYMENT);

                // Transfer repayment from user to contract
                IERC20(token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    selectedLoan.principalAmount
                );
                IERC20(token).safeTransferFrom(
                    msg.sender,
                    treasury,
                    pureInterest
                );

                // Update pool state
                DataTypes.PoolTokenState storage tokenState = poolTokenStates[
                    token
                ];
                tokenState.availableLiquidity += selectedLoan.principalAmount;

                // Remove the loan
                userLoans[loanIndex] = userLoans[userLoans.length - 1]; // Swap with last element
                userLoans.pop(); // Remove last element

                emit LoanRepayed(msg.sender, token, totalDue, loanId); // Emit loanId
                break;
            }
        }

        require(loanFound, Errors.NO_ACTIVE_LOAN);
    }

    /// @inheritdoc ILendingPool
    function liquidate(address user) external virtual override nonReentrant {
        require(isLiquidatable(user), Errors.NOT_LIQUIDATABLE);

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            address collateralToken = collateralTokens[i];
            if (userCollaterals[user][collateralToken] != 0) {
                _liquidateCollateral(user, collateralToken, 0);
            }
        }

        emit EntireCollateralLiquidated(user);
    }

    /**
     * @dev Liquidates a specified amount of a user's collateral.
     * @param user The address of the user whose collateral will be liquidated.
     * @param collateral The address of the collateral token to liquidate.
     * @param amount The amount of collateral to liquidate. If set to 0, the entire collateral balance will be liquidated.
     */
    function _liquidateCollateral(
        address user,
        address collateral,
        uint256 amount
    ) internal {
        require(isCollateral[collateral], Errors.UNSUPPORTED_COLLATERAL);

        // check if this liquidateCollateral will need to be used independently, thus need this require statement.
        require(isLiquidatable(user), Errors.NOT_LIQUIDATABLE);

        if (amount == 0) {
            // TODO!: Implement detailed liquidation logic here with the entire collateral balance.
            userCollaterals[user][collateral] = 0;
        } else {
            // TODO!: Implement detailed liquidation logic here with the amount of the collateral
            userCollaterals[user][collateral] -= amount;
        }
    }

    function getPriceOracleAddress() external view returns (address) {
        return address(priceOracleAddress);
    }
}
