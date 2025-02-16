// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../dependencies/openzeppelin/contracts/IERC20.sol";

/**
  * @title LendingStorage
  * @notice This contract stores the data related to loans, collateral, and lending tokens. 
  *         It is primarily used by the LendingPool to interact with and manage users' loans and collateral.
*/
contract LendingStorage {
  
  /**
    * @dev Loan struct represents the details of a user's loan.
    * @param amount The borrowed amount of the lending token
    * @param collateralAmount The value of collateral provided by the borrower
    * @param interestRate The interest rate applied to the loan
    * @param lastUpdated The timestamp of the last update to the loan
  */
  struct Loan {
    uint256 amount;
    uint256 collateralAmount;
    uint256 interestRate;
    uint256 lastUpdated;
  }

  // The address of the LendingPool contract
  address public lendingPool;
  // The address of the treasury where collected fees are stored
  address public treasury;
  // The address of the price oracle used to get token prices
  address public priceOracle;

  // Mappings to check if a token is accepted as collateral or a lending token
  mapping(address => bool) public isCollateral;
  mapping(address => bool) public isLendingToken;
  
  // Arrays to store the lists of collateral and lending tokens
  address[] public lendingTokens;
  address[] public collateralTokens;

  // Mappings to store user-specific loan and collateral data
  mapping(address => mapping(address => Loan)) public loans; // borrower -> token -> Loan data
  mapping(address => mapping(address => uint256)) public userCollateral; // user -> token -> amount

  /**
    * @dev Modifier to restrict access to only the LendingPool contract.
  */
  modifier onlyLendingPool() {
    require(msg.sender == lendingPool, "Only LendingPool can modify storage");
    _;
  }

  /**
    * @dev Constructor to initialize the LendingStorage contract.
    * @param _treasury The address of the treasury contract.
    * @param _priceOracle The address of the price oracle contract.
  */
  constructor(address _treasury, address _priceOracle) {
    lendingPool = msg.sender; // LendingPool deploys this contract
    treasury = _treasury;
    priceOracle = _priceOracle;
  }

  /**
    * @dev Add a collateral token to the system.
    * @param token The address of the collateral token to be added.
    * @notice Only the LendingPool contract can call this function.
    */
  function addCollateralToken(address token) external onlyLendingPool {
    require(!isCollateral[token], "Already added");
    isCollateral[token] = true;
    collateralTokens.push(token);
  }

  /**
    * @dev Add a lending token to the system.
    * @param token The address of the lending token to be added.
    * @notice Only the LendingPool contract can call this function.
  */
  function addLendingToken(address token) external onlyLendingPool {
    require(!isLendingToken[token], "Already added");
    isLendingToken[token] = true;
    lendingTokens.push(token);
  }

  /**
    * @dev Calculate the total debt of a user across all lending tokens.
    * @param user The address of the user whose total debt is being calculated.
    * @return The total debt of the user in terms of the borrowed amount.
  */
  function getUserTotalDebt(address user) external view returns (uint256) {
    uint256 totalDebt = 0;
    // Iterate through all lending tokens and sum the user's loan amounts
    for (uint256 i = 0; i < lendingTokens.length; i++) {
      address token = lendingTokens[i];
      totalDebt += loans[user][token].amount;
    }
    return totalDebt;
  }
}
