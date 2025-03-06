// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
/**
 * @title Blackout
 * @dev A game where players toggle lights on/off. Each toggle costs dynamic amount of ETH (exponential).
 * When the price is 0, and the lights are off, the contract balance can be withdrawn by any player.
 */
contract Blackout {
    bool public lightsOn = true;
    uint64 public toggleCount = 1;
    uint256 public immutable START_BLOCK;
    uint256 public immutable TARGET_BLOCKS;

    error LightsOnCannotWithdraw();
    error CurrentPriceGreaterThanZero();
    error InsufficientValue();

    constructor(uint256 targetBlocks) {
        START_BLOCK = block.number;
        TARGET_BLOCKS = targetBlocks;
    }

    /**
     * @dev Toggles the state of the lights and updates the game state.
     * Requires the player to pay the current dynamic price.
     */
    function toggle() external payable {
        uint256 currentPrice = getCurrentPrice();
        if (msg.value < currentPrice) {
            revert InsufficientValue();
        }

        // Toggle the lights
        lightsOn = !lightsOn;
        toggleCount++;

        // Refund any excess ETH sent
        if (msg.value > currentPrice) {
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - currentPrice);
        }
    }

    /**
     * @dev Calculates the current price for toggling the lights.
     * @return The current price in wei.
     */
    function getCurrentPrice() public view returns (uint256) {
        uint256 expectedToggleCount = ((block.number - START_BLOCK) / TARGET_BLOCKS) + 1;
        uint256 exponent = toggleCount / expectedToggleCount;
        if (exponent > 255) {
          return type(uint256).max;
        }
        return (2 ** exponent) - 1;
    }

    /**
     * @dev Allows withdraw by any player if the lights are off and the current price is 0
     */
    function withdraw() external {
        if (lightsOn) {
            revert LightsOnCannotWithdraw();
        }
        uint256 currentPrice = getCurrentPrice();
        if (currentPrice > 0) {
            revert CurrentPriceGreaterThanZero();
        }

        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
}
