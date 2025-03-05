// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Blackout
 * @dev A game where players toggle lights on/off. The last player to turn off the lights
 * and maintain that state for 5000 blocks wins the accumulated ETH.
 */
contract Blackout {
    bool public lightsOn;
    uint256 public toggleCount;
    uint256 public lastToggleBlock;
    address public lastToggler;
    uint256 public constant BASE_PRICE = 1 wei;

    /**
     * @dev Toggles the state of the lights and updates the game state.
     * Requires the sender to pay the current dynamic price.
     */
    function toggle() external payable {
        uint256 currentPrice = getCurrentPrice();
        require(msg.value >= currentPrice, "Insufficient ETH sent");

        // Refund any excess ETH sent
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

        // Toggle the lights
        lightsOn = !lightsOn;
        toggleCount++;
        lastToggleBlock = block.number;
        lastToggler = msg.sender;
    }

    /**
     * @dev Calculates the current price for toggling the lights.
     * @return The current price in wei.
     */
    function getCurrentPrice() public view returns (uint256) {
        return BASE_PRICE * (2 ** toggleCount);
    }

    /**
     * @dev Allows the last toggler to withdraw the contract balance if 5000 blocks have passed.
     */
    function withdraw() external {
        require(block.number >= lastToggleBlock + 5000, "Game is still active");
        require(!lightsOn, "Lights must be off to withdraw");
        require(msg.sender == lastToggler, "Only the last toggler can withdraw");

        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
} 