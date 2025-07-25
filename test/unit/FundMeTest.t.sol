//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {MockV3Aggregator} from "../../test/mocks/MockV3Aggregator.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address alice = makeAddr("alice");
    MockV3Aggregator mockPriceFeed;

    uint256 constant SEND_ETHER = 5 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    receive() external payable {}

    function setUp() external {
        mockPriceFeed = new MockV3Aggregator(8, 2000e8);
        fundMe = new FundMe(address(mockPriceFeed));

        vm.deal(alice, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerisMsgSender() public view {
        assertEq(fundMe.getOwner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value
    }

    function testFundUpdatesFundDataStructure() public {
        vm.prank(alice);
        fundMe.fund{value: SEND_ETHER}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_ETHER);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(alice);
        fundMe.fund{value: SEND_ETHER}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);
    }

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_ETHER}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(alice);
        vm.expectRevert(); //if this function was above it will ignore vm.prank below it because it is a cheatcode for a transaction - the withdraw transaction
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        // Set a gas price for the transaction

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // we get hoax from stdcheats
        // prank + deal
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_ETHER);
            fundMe.fund{value: SEND_ETHER}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert

        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // we get hoax from stdcheats
        // prank + deal
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_ETHER);
            fundMe.fund{value: SEND_ETHER}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert

        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }
}
