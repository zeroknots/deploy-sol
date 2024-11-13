// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

struct ModuleDeployment {
    string name;
    address addr;
}

contract DeployScript is Script {
    function setUp() public {}

    function run() public virtual {}

    function _deployModule() virtual;
}
