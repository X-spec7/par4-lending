// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IParfStorage} from "../interfaces/IParfStorage.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {InterestCalculator} from "../libraries/helpers/InterestCalculator.sol";

/**
 * @title ParfStorage
 * @notice This contract stores the data related to loans, collateral, and lending tokens.
 *         It is primarily used by the LendingPool to interact with and manage users' loans and collateral.
 */
abstract contract ParfStorage is IParfStorage {
    using InterestCalculator for DataTypes.Loan;

    /// @dev Tracking the loan id, increased everytime new loan is added
    uint256 loanId = 0;

    /// @dev The address of the LendingPool contract
    address public lendingPool;
    /// @dev The address of the treasury where collected fees are stored
    address public treasury;
    /// @dev The address of the price oracle used to get token prices
    address public priceOracleAddress;

    /// @dev The addresses of the assets
    address immutable usdcAddress;
    address immutable usdtAddress;
    address immutable daiAddress;
    address immutable wETHAddress;
    address immutable wBTCAddress;

    /// @dev Aggregate variables tracked for the entire market
    /// @dev Indexes accrued interests since the begining of the pool
    /// @dev tracking for total supplying and borrowing of base tokens
    uint40 internal usdcLastAccrualTime;
    uint40 internal usdtLastAccrualTime;
    uint40 internal daiLastAccrualTime;

    uint64 internal usdcBaseSupplyIndex;
    uint64 internal usdcBaseBorrowIndex;
    uint64 internal usdtBaseBorrowIndex;
    uint64 internal usdtBaseSupplyIndex;
    uint64 internal daiBaseSupplyIndex;
    uint64 internal daiBaseBorrowIndex;

    uint104 internal usdcSupplyBase;
    uint104 internal usdcBorrowBase;
    uint104 internal usdtSupplyBase;
    uint104 internal usdtBorrowBase;
    uint104 internal daiSupplyBase;
    uint104 internal daiBorrowBase;

    // TODO: remove these and migrate checking collateral and base token logic to getting setting
    /// @dev Mappings to check if a token is accepted as collateral or a lending token
    mapping(address => bool) public isCollateral;
    mapping(address => bool) public isLendingToken;

    /// @dev Mappings for total supplied amount for each collateral
    mapping(address => uint128) public totalCollateralAmount;

    // TODO: remove these
    // Arrays to store the lists of collateral and lending tokens
    address[] public lendingTokens;
    address[] public collateralTokens;

    mapping(address => DataTypes.Loan[]) public loans; // borrower -> Loan data

    /// @dev lending and borrowing principal values
    mapping(address => mapping(address => uint104))
        public userLendingPrincipals; // user -> token -> principal lending value
    mapping(address => mapping(address => uint104))
        public userBorrowingPrincipals; // user -> token -> principal borrowing value

    mapping(address => mapping(address => uint256)) public userCollaterals; // user -> token -> amount

    mapping(address => DataTypes.PoolTokenState) public poolTokenStates; // token -> PoolTokenState

    /// @inheritdoc IParfStorage
    function addCollateralToken(address token) external {
        require(!isCollateral[token], Errors.COLLATERAL_ALREADY_ADDED);
        isCollateral[token] = true;
        collateralTokens.push(token);
        emit LendingTokenAdded(token);
    }

    /// @inheritdoc IParfStorage
    function addLendingToken(address token) external {
        require(!isLendingToken[token], Errors.LENDING_TOKEN_ALREADY_ADDED);
        isLendingToken[token] = true;
        lendingTokens.push(token);
        emit CollateralTokenAdded(token);
    }

    /// @inheritdoc IParfStorage
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

            uint256 accruedInterest = loan.calculateAccruedInterest(
                getUtilizationRate(loan.principalToken)
            );

            totalDebt += (loan.principalAmount + accruedInterest) * tokenPrice;
        }

        return totalDebt;
    }

    /// @inheritdoc IParfStorage
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

    /// @inheritdoc IParfStorage
    function getBorrowLimit(
        address user
    ) public view override returns (uint256) {
        return (getUserCollateralValue(user) * 75) / 100; // 75% Loan-to-Value (LTV) ratio
    }

    /// @inheritdoc IParfStorage
    function isLiquidatable(address user) public view override returns (bool) {
        return
            getUserCollateralValue(user) < (getUserTotalDebt(user) * 125) / 100;
    }

    /// @inheritdoc IParfStorage
    function getUtilizationRate(
        address token
    ) public view override returns (uint256) {
        DataTypes.PoolTokenState storage tokenState = poolTokenStates[token];

        uint256 utilizationRate = (tokenState.grossLiquidity -
            tokenState.availableLiquidity) / tokenState.grossLiquidity;

        return utilizationRate;
    }
}
