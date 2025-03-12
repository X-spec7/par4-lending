// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {InterestCalculator} from "../libraries/helpers/InterestCalculator.sol";

/**
 * @title ParfStorage
 * @notice This contract stores the data related to loans, collateral, and lending tokens.
 *         It is primarily used by the LendingPool to interact with and manage users' loans and collateral.
 */
abstract contract ParfStorage {
    /// @dev Tracking the loan id, increased everytime new loan is added
    uint256 loanId = 0;

    /// @dev The address of the LendingPool contract
    address public lendingPool;
    /// @dev The address of the price oracle used to get token prices
    address public priceOracleAddress;

    /// @dev The addresses of the assets
    address immutable baseToken;
    address immutable wETHAddress;
    address immutable wBTCAddress;

    /// @dev Aggregate variables tracked for the entire market
    /// @dev Indexes accrued interests since the begining of the pool
    /// @dev tracking for total supplying and borrowing of base tokens
    uint40 internal lastAccrualTime;
    uint64 internal baseSupplyIndex;
    uint64 internal baseBorrowIndex;

    uint104 internal supplyBase;
    uint104 internal borrowBase;

    // TODO: remove these and migrate checking collateral and base token logic to getting setting
    /// @dev Mappings to check if a token is accepted as collateral or a lending token
    mapping(address => bool) public isCollateral;

    /// @dev Mappings for total supplied amount for each collateral
    mapping(address => uint128) public totalCollateralAmount;

    // TODO: remove this
    // Arrays to store the lists of collateral and lending tokens
    address[] public collateralTokens;

    mapping(address => DataTypes.Loan[]) public loans; // borrower -> Loan data

    /// @dev lending and borrowing principal values
    mapping(address => mapping(address => uint104))
        public userLendingPrincipals; // user -> token -> principal lending value
    mapping(address => mapping(address => uint104))
        public userBorrowingPrincipals; // user -> token -> principal borrowing value

    mapping(address => mapping(address => uint256)) public userCollaterals; // user -> token -> amount
}
