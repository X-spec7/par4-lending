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
    address borrower;                     // Address of the borrower
    address principalToken;               // The token in which the loan is denominated
    uint256 principalAmount;              // The initial borrowed amount
    uint256 annualInterestRateBasisPoints;// Annual interest rate in basis points (e.g., 500 = 5%)
    LoanTerm term;                        // Duration of the loan term
    uint16 remainingPayments;             // Number of remaining scheduled payments
    uint256 startTimestamp;               // Timestamp when the loan was issued
    uint256 lastPaymentTimestamp;         // Timestamp of the most recent payment
  }

  struct LendingPosition {
    address lender;               // Address of the lender
    address lendingToken;         // The token being lent into the pool
    uint256 amount;               // The amount of tokens lent
    uint256 depositTimestamp;     // Timestamp when the tokens were deposited
    uint256 lastActionTimestamp;  // Timestamp for the last action on this position
  }
}
