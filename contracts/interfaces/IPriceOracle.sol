// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPriceOracle Interface
 * @notice This interface defines the methods for a price oracle contract
 *         that provides price feeds for tokens.
 */
interface IPriceOracle {
    /**
     * @notice Emitted when the price feed for a token is updated.
     * @param token The address of the token whose price feed was updated.
     * @param feed The address of the new price feed.
     */
    event PriceFeedUpdated(address indexed token, address indexed feed);

    /**
     * @notice Sets or updates the price feed for a given token.
     * @param token The address of the token for which the price feed is set.
     * @param feed The address of the price feed contract.
     */
    function setPriceFeed(address token, address feed) external;

    /**
     * @notice Retrieves the current price for a given token.
     * @param token The address of the token whose price is being queried.
     * @return The current price of the token as a uint256.
     */
    function getPrice(address token) external view returns (uint256);
}
