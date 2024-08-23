//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { Crowdfunding } from '../src/Crowdfunding.sol';

contract DeployCrowdfunding is Script {

    function run() external returns (Crowdfunding) {
        vm.startBroadcast();
        Crowdfunding crowdfunding = new Crowdfunding();
        vm.stopBroadcast();
        return crowdfunding;
    }
}
