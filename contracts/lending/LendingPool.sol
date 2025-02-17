// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../dependencies/openzeppelin/contracts/IERC20.sol";
import { SafeERC20 } from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import { ReentrancyGuard } from "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";
import { Ownable } from "../dependencies/openzeppelin/contracts/Ownable.sol";
import { Initializable } from "../dependencies/openzeppelin/proxy/Initializable.sol";

import { CollateralManager } from  "./CollateralManager.sol";
import { InterestRateModel } from"./InterestRateModel.sol";
import { PriceOracle } from "../utils/PriceOracle.sol";
import { ILendingPool } from "../interfaces/ILendingPool.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { LendingPoolStorage } from "./LendingPoolStorage.sol";

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
contract LendingPool is ILendingPool, LendingPoolStorage, ReentrancyGuard, Ownable, Initializable {
  using SafeERC20 for IERC20;

  // Fee structure (39 basis points = 0.39%)
  uint256 public constant FEE_BPS = 39;
  uint256 public constant BPS_DIVISOR = 10000;

  // Collateral Manager
  CollateralManager public collateralManager;
  // Interest Rate Model
  InterestRateModel public interestRateModel;

  function initialize(
    address _interestRateModel,
    address _treasury
  ) external initializer {
    interestRateModel = InterestRateModel(_interestRateModel);
    priceOracleAddress = address(new PriceOracle());
    treasury = _treasury;
  }

  /// @inheritdoc ILendingPool
  function supply(
    address asset,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isLendingToken[asset], "Invalid lending token");

    // Transfer the asset from the user to the lending pool
    IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

    // Emit event that asset has been supplied
    emit AssetSupplied(msg.sender, asset, amount);
  }

  /// @inheritdoc ILendingPool
  function lenderWithdraw(
    address asset,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isLendingToken[asset], "Invalid lending token");

    // Check if the user has enough balance to withdraw
    uint256 lenderBalance = IERC20(asset).balanceOf(address(this));
    require(lenderBalance >= amount, "Insufficient liquidity in pool");

    // Transfer the specified amount back to the lender
    IERC20(asset).safeTransfer(msg.sender, amount);

    // Emit event that the asset has been withdrawn by the lender
    emit AssetWithdrawn(msg.sender, asset, amount);
  }

  /// @inheritdoc ILendingPool
  function depositCollateral(
    address collateral,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isCollateral[collateral], "Unsupported collateral");
    IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
    userCollateral[msg.sender][collateral] += amount;
    emit CollateralDeposited(msg.sender, collateral, amount);
  }

  /// @inheritdoc ILendingPool
  function withdrawCollateral(
    address collateral,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isCollateral[collateral], "Unsupported collateral");
    IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
    uint256 remainingValue = getUserCollateralValue(msg.sender) - priceOracle.getPrice(collateral) * amount;
    require(remainingValue >= getUserTotalDebt(msg.sender) * 125 / 100, "Collateral below required threshold");
    userCollateral[msg.sender][collateral] -= amount;
    IERC20(collateral).transfer(msg.sender, amount); 
    emit CollateralWithdrawn(msg.sender, collateral, amount);
  }

  /// @inheritdoc ILendingPool
  function borrow(
    address token,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isLendingToken[token], "Unsupported lending token");

    uint256 maxBorrow = collateralManager.getBorrowLimit(msg.sender);
    require(amount <= maxBorrow, "Exceeds borrowing limit");

    uint256 totalLiquidity = IERC20(token).balanceOf(address(this));

    uint256 interestRate = interestRateModel.calculateInterestRate(token, amount, totalLiquidity);
    loans[msg.sender][token] = Loan(amount, collateralManager.getCollateralValue(msg.sender), interestRate, block.timestamp);

    IERC20(token).safeTransfer(msg.sender, amount);
    emit Borrow(msg.sender, token, amount, collateralManager.getCollateralValue(msg.sender));
  }

  /// @inheritdoc ILendingPool
  function repayLoan(
    address token,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isLendingToken[token], "Invalid lending token");
    Loan storage loan = loans[msg.sender][token];
    require(loan.amount > 0, "No active loan");

    uint256 interest = ((block.timestamp - loan.lastUpdated) * loan.amount * loan.interestRate) / (365 days * 100);
    uint256 totalDue = loan.amount + interest;

    require(amount >= totalDue, "Insufficient repayment");

    IERC20(token).safeTransferFrom(msg.sender, address(this), totalDue);
    delete loans[msg.sender][token];

    emit LoanRepayed(msg.sender, token, totalDue);
  }

  /// @inheritdoc ILendingPool
  function liquidate(
    address user,
    address token
  ) external virtual override nonReentrant {
    require(isLendingToken[token], "Invalid lending token");
    require(collateralManager.isLiquidatable(user), "Collateral is sufficient");

    uint256 loanAmount = loans[user][token].amount;
    collateralManager.liquidate(user, token, loanAmount);

    delete loans[user][token];

    emit CollateralLiquidated(user, token, loanAmount);
  }

  function getPriceOracleAddress() external view returns (address) {
    return address(priceOracleAddress);
  }
}
