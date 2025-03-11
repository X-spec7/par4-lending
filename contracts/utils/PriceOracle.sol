// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../dependencies/openzeppelin/contracts/Ownable.sol";
import "../dependencies/chainlink/AggregatorV3Interface.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle {
    mapping(address => address) public priceFeeds;
    address public lendingPool;

    modifier onlyLendingPool() {
        require(
            msg.sender == lendingPool,
            "Only LendingPool can call this function"
        );
        _;
    }

    constructor() {
        lendingPool = msg.sender; // Price Oracle is deployed by Lending pool
    }

    /// @inheritdoc IPriceOracle
    function setPriceFeed(
        address token,
        address feed
    ) external override onlyLendingPool {
        priceFeeds[token] = feed;
        emit PriceFeedUpdated(token, feed);
    }

    /// @inheritdoc IPriceOracle
    function getPrice(address token) external view override returns (uint256) {
        require(priceFeeds[token] != address(0), "No price feed available");

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeeds[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price data");

        return uint256(price);
    }
}
