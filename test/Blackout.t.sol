// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Blackout.sol";

contract BlackoutTest is Test {
    Blackout blackout;
    address player1 = address(1);
    address player2 = address(2);

    function setUp() public {
        blackout = new Blackout(5000);
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
    }

    function testInitialState() public {
        assertEq(blackout.lightsOn(), true);
        assertEq(blackout.toggleCount(), 1);
    }

    function testToggleLights() public {
        uint256 price = blackout.getCurrentPrice();
        vm.prank(player1);
        blackout.toggle{value: price}();
        assertEq(blackout.lightsOn(), false);
        assertEq(blackout.toggleCount(), 2);
    }

    function testToggleInsufficientETH() public {
        uint256 price = blackout.getCurrentPrice();
        vm.prank(player1);
        vm.expectRevert(Blackout.InsufficientValue.selector);
        blackout.toggle{value: price - 1}();
    }

    function testRefundExcessETH() public {
        uint256 price = blackout.getCurrentPrice();
        uint256 excess = 1 ether;
        vm.prank(player1);

        blackout.toggle{value: price + excess}();

        assertEq(player1.balance, 10 ether - price);
    }

    function testWithdrawFailsWhenLightsOn() public {
        vm.prank(player1);
        vm.expectRevert(Blackout.LightsOnCannotWithdraw.selector);
        blackout.withdraw();
    }

    function testWithdrawFailsWhenPriceGreaterThanZero() public {
        uint256 price = blackout.getCurrentPrice();
        vm.prank(player1);
        blackout.toggle{value: price}(); // lights off

        vm.roll(block.number + 5000);
        vm.prank(player1);
        vm.expectRevert(Blackout.CurrentPriceGreaterThanZero.selector);
        blackout.withdraw();
    }

    function testSuccessfulWithdraw() public {
        uint256 price1 = blackout.getCurrentPrice();
        vm.prank(player1);
        blackout.toggle{value: price1}(); // lights off

        uint256 price2 = blackout.getCurrentPrice();
        vm.prank(player2);
        blackout.toggle{value: price2}(); // lights on

        uint256 price3 = blackout.getCurrentPrice();
        vm.prank(player1);
        blackout.toggle{value: price3}(); // lights off again

        vm.roll(block.number + 20000);
        vm.prank(player1);
        blackout.withdraw();

        assertEq(player1.balance, 10 ether + price2);
        assertEq(address(blackout).balance, 0);
    }
}
