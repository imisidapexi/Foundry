// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

pragma solidity ^0.8.19;

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        vm.startBroadcast();
        FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // This is just to ensure the contract is deployed correctly
        vm.stopBroadcast();
        return fundMe;
    }
}
