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
contract LendingPool is ILendingPool, ReentrancyGuard, Ownable, Initializable {
  using SafeERC20 for IERC20;

  // Accepted collateral assets
  mapping(address => bool) public isCollateral;
  // Accepted lending tokens
  mapping(address => bool) public isLendingToken;

  // Fee structure (39 basis points = 0.39%)
  uint256 public constant FEE_BPS = 39;
  uint256 public constant BPS_DIVISOR = 10000;
  
  // Treasury for collecting fees
  address public treasury;

  address[] public lendingTokens;

  // Collateral Manager
  CollateralManager public collateralManager;
  // Interest Rate Model
  InterestRateModel public interestRateModel;
  // Price Oracle
  PriceOracle public priceOracle;

  struct Loan {
    uint256 amount;
    uint256 collateralAmount;
    uint256 interestRate;
    uint256 lastUpdated;
  }

  mapping(address => mapping(address => Loan)) public loans; // borrower -> token -> Loan data

  function initialize(
    address _interestRateModel,
    address _treasury
  ) external initializer {
    interestRateModel = InterestRateModel(_interestRateModel);
    priceOracle = new PriceOracle();
    collateralManager = new CollateralManager(address(priceOracle));
    treasury = _treasury;
  }

  /// @inheritdoc ILendingPool
  function supply(
    address asset,
    uint256 amount
  ) external virtual override {

  }

  /// @inheritdoc ILendingPool
  function lenderWithdraw(
    address asset,
    uint256 amount
  ) external virtual override {

  }

  /// @inheritdoc ILendingPool
  function depositCollateral(
    address collateral,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isCollateral[collateral], "Invalid collateral");
    IERC20(collateral).safeTransferFrom(msg.sender, address(collateralManager), amount);
    collateralManager.deposit(msg.sender, collateral, amount);
    emit CollateralDeposited(msg.sender, collateral, amount);
  }

  /// @inheritdoc ILendingPool
  function borrow(
    address token,
    uint256 amount
  ) external virtual override nonReentrant {
    require(isLendingToken[token], "Invalid lending token");

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

  /// @inheritdoc ILendingPool
  function addCollateralToken(
    address token
  ) external virtual override onlyOwner {
    require(!isCollateral[token], "Already added");
    isCollateral[token] = true;
    collateralManager.addCollateralToken(token);
  }

  /// @inheritdoc ILendingPool
  function addLendingToken(
    address token
  ) external virtual override onlyOwner {
    require(!isLendingToken[token], "Already added");
    isLendingToken[token] = true;
    lendingTokens.push(token);
  }

  function getUserTotalDebt(address user) external view returns (uint256) {
    uint256 totalDebt = 0;
    for (uint256 i = 0; i < lendingTokens.length; i++) {
      address token = lendingTokens[i];
      totalDebt += loans[user][token].amount;
    }
    return totalDebt;
  }

  function getPriceOracleAddress() external view returns (address) {
    return address(priceOracle);
  }
}
