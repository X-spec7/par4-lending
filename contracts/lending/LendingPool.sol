// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CollateralManager.sol";
import "./InterestRateModel.sol";
import "../utils/PriceOracle.sol";

contract LendingPool is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Accepted collateral assets
    mapping(address => bool) public isCollateral;
    // Accepted lending tokens
    mapping(address => bool) public isLendingToken;

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

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Borrow(address indexed user, address indexed token, uint256 amount, uint256 collateralAmount);
    event Repay(address indexed user, address indexed token, uint256 amount);
    event Liquidation(address indexed user, address indexed token, uint256 amount);

    constructor(
        address _collateralManager,
        address _interestRateModel,
        address _priceOracle
    ) {
        collateralManager = CollateralManager(_collateralManager);
        interestRateModel = InterestRateModel(_interestRateModel);
        priceOracle = PriceOracle(_priceOracle);
    }

    function depositCollateral(address collateral, uint256 amount) external nonReentrant {
        require(isCollateral[collateral], "Invalid collateral");
        IERC20(collateral).safeTransferFrom(msg.sender, address(collateralManager), amount);
        collateralManager.deposit(msg.sender, collateral, amount);
        emit Deposit(msg.sender, collateral, amount);
    }

    function borrow(address token, uint256 amount) external nonReentrant {
        require(isLendingToken[token], "Invalid lending token");

        uint256 maxBorrow = collateralManager.getBorrowLimit(msg.sender, token);
        require(amount <= maxBorrow, "Exceeds borrowing limit");

        uint256 interestRate = interestRateModel.calculateInterestRate(token, amount);
        loans[msg.sender][token] = Loan(amount, collateralManager.getCollateralValue(msg.sender), interestRate, block.timestamp);

        IERC20(token).safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, token, amount, collateralManager.getCollateralValue(msg.sender));
    }

    function repay(address token, uint256 amount) external nonReentrant {
        require(isLendingToken[token], "Invalid lending token");
        Loan storage loan = loans[msg.sender][token];
        require(loan.amount > 0, "No active loan");

        uint256 interest = ((block.timestamp - loan.lastUpdated) * loan.amount * loan.interestRate) / (365 days * 100);
        uint256 totalDue = loan.amount + interest;

        require(amount >= totalDue, "Insufficient repayment");

        IERC20(token).safeTransferFrom(msg.sender, address(this), totalDue);
        delete loans[msg.sender][token];

        emit Repay(msg.sender, token, totalDue);
    }

    function liquidate(address user, address token) external nonReentrant {
        require(isLendingToken[token], "Invalid lending token");
        require(collateralManager.isLiquidatable(user), "Collateral is sufficient");

        uint256 loanAmount = loans[user][token].amount;
        collateralManager.liquidate(user, token, loanAmount);

        delete loans[user][token];

        emit Liquidation(user, token, loanAmount);
    }

    function addCollateralToken(address token) external onlyOwner {
        isCollateral[token] = true;
    }

    function addLendingToken(address token) external onlyOwner {
        isLendingToken[token] = true;
    }
}
