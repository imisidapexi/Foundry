//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "../../test/mocks/MockV3Aggregator.sol";

contract InteractionsTest is Test {
    FundMe public fundMe = new FundMe(address(mockAggregator));
    DeployFundMe deployFundMe;
    // Constants for testing
    uint256 public constant SEND_ETHER = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address alice = makeAddr("alice");
    MockV3Aggregator mockAggregator;

    receive() external payable {}

    function setUp() external {
        mockAggregator = new MockV3Aggregator(8, 2000e8); // $2000
        fundMe = new FundMe(address(mockAggregator));
        vm.deal(alice, 1 ether);
    }

    function testUserCanFundAndOwnerWithdraw() public {
        uint256 preUserBalance = address(alice).balance;
        uint256 preOwnerBalance = address(fundMe.getOwner()).balance;

        // Using vm.prank to simulate funding from the USER address
        vm.prank(alice);
        fundMe.fund{value: SEND_ETHER}();

        fundMe.withdraw();
        uint256 afterUserBalance = address(alice).balance;
        uint256 afterOwnerBalance = address(fundMe.getOwner()).balance;
        assert(address(fundMe).balance == 0);
        assertEq(afterUserBalance + SEND_ETHER, preUserBalance);
        assertEq(preOwnerBalance + SEND_ETHER, afterOwnerBalance);
    }
}
