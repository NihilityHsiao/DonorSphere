// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {DAOHandler} from "../src/DAOHandler.sol";
import {DAOToken} from "../src/Token.sol";
import {Script, console} 
from "lib/forge-std/src/Script.sol";
contract DAOHandlerScript is Script {
    function setUp() public {}
     DAOToken public token_contract;   
    DAOHandler public nft_contract;
    function run() public {
         uint privatekey=vm.envUint("DEV_PRIVATE_KEY");
        address account=vm.addr(privatekey);
        console.log(account);
        vm.startBroadcast(vm.addr(privatekey));
        //deploy contract
        token_contract = new DAOToken(account);

        nft_contract=new DAOHandler(token_contract);
        vm.stopBroadcast();
    }
}
