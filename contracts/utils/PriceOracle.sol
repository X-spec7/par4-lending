// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/AggregatorV3Interface.sol";

contract PriceOracle {
    mapping(address => address) public priceFeeds;

    event PriceFeedUpdated(address indexed token, address indexed feed);

    function setPriceFeed(address token, address feed) external {
        priceFeeds[token] = feed;
        emit PriceFeedUpdated(token, feed);
    }

    function getPrice(address token) external view returns (uint256) {
        require(priceFeeds[token] != address(0), "No price feed available");

        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeeds[token]);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price data");

        return uint256(price);
    }
}
