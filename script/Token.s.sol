// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {DAOToken} from "../src/Token.sol";
import {Script, console} 
from "lib/forge-std/src/Script.sol";
contract TokenScript is Script {
    function setUp() public {}
        
    DAOToken public token_contract;
    function run() public {
        uint privatekey=vm.envUint("DEV_PRIVATE_KEY");
        address account=vm.addr(privatekey);
        console.log(account);
        vm.startBroadcast(vm.addr(privatekey));
        //deploy contract
        token_contract = new DAOToken(account);
        vm.stopBroadcast();
    }
}
