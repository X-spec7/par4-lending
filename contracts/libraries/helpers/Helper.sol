// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "../types/DataTypes.sol";

library Helper {
    // Helper function to calculate payments based on selected term
    function calculatePayments(
        DataTypes.LoanTerm term
    ) internal pure returns (uint16) {
        if (term == DataTypes.LoanTerm.SEVEN_DAYS) return 1;
        if (term == DataTypes.LoanTerm.THIRTY_DAYS) return 1;
        if (term == DataTypes.LoanTerm.NINETY_DAYS) return 3;
        if (term == DataTypes.LoanTerm.ONE_HUNDRED_EIGHTY_DAYS) return 6;
        if (term == DataTypes.LoanTerm.THREE_SIXTY_DAYS) return 12;
        revert("Invalid loan term");
    }
}
