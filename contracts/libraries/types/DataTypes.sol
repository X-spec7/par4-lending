// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library DataTypes {
    enum LoanTerm {
        SEVEN_DAYS,
        THIRTY_DAYS,
        NINETY_DAYS,
        ONE_HUNDRED_EIGHTY_DAYS,
        THREE_SIXTY_DAYS
    }

    struct Loan {
        uint256 loanId; // Unique id for Loan
        address borrower; // Address of the borrower
        address principalToken; // The token in which the loan is denominated
        uint256 principalAmount; // The initial borrowed amount
        LoanTerm term; // Duration of the loan term
        uint16 remainingPayments; // Number of remaining scheduled payments
        uint256 startTimestamp; // Timestamp when the loan was issued
        uint256 lastPaymentTimestamp; // Timestamp of the most recent payment
    }

    /// @dev Store whether a certain collateral is used, a certain base asset is deposited, or borrowed
    struct UserBasic {
        uint104 principal;
        uint16 assetsIn;
    }

    struct TokenPrice {
        address token; // The address of the token
        uint256 price; // The USD price of the token
    }
}
