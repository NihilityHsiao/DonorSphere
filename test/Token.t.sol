// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/forge-std/src/Test.sol";
import "../src/Token.sol";


contract tokenErc is Test{
    DAOToken _erc20Token;

    uint256 internal makerPrivateKey;
    address internal maker;

    uint256 internal takerPrivateKey;
    address internal taker;
      /**
     * Initializes the contract by creating instances of Token and PROJECT contracts.
     */
    function setUp() public {
        
        makerPrivateKey = 0xA11CE;
        maker = vm.addr(makerPrivateKey);
        
        takerPrivateKey = 0xB0B;
        taker = vm.addr(takerPrivateKey);

        //giving 2 ether to taker
        vm.deal(taker, 2 ether);
        
        vm.prank(maker);
        _erc20Token = new DAOToken(maker);
         // Stop the prank 
        vm.stopPrank();
    }

    function test_checkOwner()public view{
      assert(_erc20Token.owner()==maker);
    }
    
    
    function test_buyToken() public {
        // Mocking setup
        vm.prank(taker); // Potentially unnecessary, depending on the purpose of `prank`
        
        // Mint tokens to the taker
        _erc20Token.mint{value: 0.1 ether}(taker, 1);
        
        // End mocking
        vm.stopPrank(); // Potentially unnecessary, depending on the purpose of `stopPrank`
        
        // Verify balance of taker
        uint256 takerBalance = _erc20Token.balanceOf(taker);
        assert(takerBalance == 1*10**18);
        assert(_erc20Token.balanceOf(maker)==1000*10**18);
        // Verify total supply
        assertEq(1001*10**18, _erc20Token.totalSupply(), "Total supply should be 1001 tokens");
        assertEq(address(taker).balance,1.9 ether);
    }


    function test_buyTokenwithzerobalance() public {
        // Mocking setup
        vm.prank(taker); // Potentially unnecessary, depending on the purpose of `prank`
        vm.expectRevert("Insufficient Ether sent.");
        // Mint tokens to the taker
        _erc20Token.mint{value: 0.1 ether}(taker, 2);
        
        // End mocking
        vm.stopPrank(); // Potentially unnecessary, depending on the purpose of `stopPrank`
        
    }


    function test_checkUpdatePrice()public{
        vm.prank(maker);
        assertEq(_erc20Token.tokenPrice(),0.1 ether);
        vm.stopPrank();
       vm.prank(maker);
       _erc20Token.updateTokenPrice(0.2 ether);
       vm.stopPrank();

       assertEq(_erc20Token.tokenPrice(), 0.2 ether);
       

         vm.prank(taker); // Potentially unnecessary, depending on the purpose of `prank`
        
        // Mint tokens to the taker
        _erc20Token.mint{value: 0.2 ether}(taker, 1);
        
        // End mocking
        vm.stopPrank(); // Potentially unnecessary, depending on the purpose of `stopPrank`
        
        // Verify balance of taker
        uint256 takerBalance = _erc20Token.balanceOf(taker);
        assert(takerBalance == 1*10**18);
        assert(_erc20Token.balanceOf(maker)==1000*10**18);
        // Verify total supply
        assertEq(1001*10**18, _erc20Token.totalSupply(), "Total supply should be 1001 tokens");
        assertEq(address(taker).balance,1.8 ether);
    }



     function test_withdrawbalance()public{
        vm.prank(maker);
        assertEq(_erc20Token.tokenPrice(),0.1 ether);
        vm.stopPrank();
       vm.prank(maker);
       _erc20Token.updateTokenPrice(0.2 ether);
       vm.stopPrank();

       assertEq(_erc20Token.tokenPrice(), 0.2 ether);
       

         vm.prank(taker); // Potentially unnecessary, depending on the purpose of `prank`
        
        // Mint tokens to the taker
        _erc20Token.mint{value: 0.2 ether}(taker, 1);
        
        // End mocking
        vm.stopPrank(); // Potentially unnecessary, depending on the purpose of `stopPrank`
        
        // Verify balance of taker
        uint256 takerBalance = _erc20Token.balanceOf(taker);
        assert(takerBalance == 1*10**18);
        assert(_erc20Token.balanceOf(maker)==1000*10**18);
        // Verify total supply
        assertEq(1001*10**18, _erc20Token.totalSupply(), "Total supply should be 1001 tokens");
        assertEq(address(taker).balance,1.8 ether);

        vm.prank(maker);
        _erc20Token.withdraw();
        vm.stopPrank();
        assertEq(address(maker).balance,0.2 ether);

    }



    function test_withdrazeroBalance()public{
        vm.prank(maker);
        vm.expectRevert("Contract balance is zero.");
        _erc20Token.withdraw();
        vm.stopPrank();
    }


    function test_burnToken() public {
        // Mocking setup
        vm.prank(taker); // Potentially unnecessary, depending on the purpose of `prank`
        
        // Mint tokens to the taker
        _erc20Token.mint{value: 0.1 ether}(taker, 1);
        
        // End mocking
        vm.stopPrank(); // Potentially unnecessary, depending on the purpose of `stopPrank`
        
        assert(_erc20Token.balanceOf(taker)==1*10**18);
        vm.prank(taker);
        _erc20Token.burnToken(taker, 1*10**18);
        vm.stopPrank();
        assert(_erc20Token.balanceOf(taker)==0);
    }
}