//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address alice = makeAddr("alice");

    uint256 constant SEND_ETHER = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        mockAggregator = new MockV3Aggregator(8, 2000e8); // $2000/ETH
        fundMe = new FundMe(address(mockAggregator));
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(alice, STARTING_BALANCE); // Give Alice some ether
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    //function testOwnerisMsgSender() public view {
    //assertEq(fundMe.i_owner(), address(this));
    //}

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
}
