// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "lib/forge-std/src/Test.sol";
import "../src/DAOHandler.sol";
import "../src/Token.sol";

contract NFT_Test is Test {
    DAOToken daoToken;
    DAOHandler nft_contract;

    uint256 internal makerPrivateKey;
    address internal maker;

    uint256 internal takerPrivateKey;
    address internal taker;

    uint256 internal offerPrivateKey;
    address internal offer;


    function setUp() public {
        makerPrivateKey = 0xA11CE;
        maker = vm.addr(makerPrivateKey);
        
        takerPrivateKey = 0xB0B;
        taker = vm.addr(takerPrivateKey);

        vm.deal(taker, 2 ether);

        offerPrivateKey = 0xB0A;
        offer = vm.addr(offerPrivateKey);

        vm.deal(offer, 2 ether);
        vm.deal(maker, 2 ether);

        vm.prank(maker);
        daoToken = new DAOToken(maker);
        nft_contract = new DAOHandler(daoToken);
        vm.stopPrank();
        nft_contract.transferOwnership(maker);
    }

     //Just register which will go for vote
    function test_registerNGOFirtTime_noDuplication()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

        vm.startPrank(maker);
        vm.expectRevert("Ngo Registeration already Exist");
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

        vm.startPrank(taker);
        vm.expectRevert("Ngo Registeration already Exist");
        nft_contract.registerationForNGO(100);
        vm.stopPrank();


        vm.startPrank(maker);
        vm.expectRevert("Address already has a registeration");
        nft_contract.registerationForNGO(200);
        vm.stopPrank();

         //new creation   
         vm.startPrank(taker);
        nft_contract.registerationForNGO(200);
        vm.stopPrank();

        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //second one ngo
         //single owner of ngo
        assert(nft_contract.ngoOwner(200)==taker);
        assert(nft_contract.ngoRegistrationNo(taker)==200);
        assert(nft_contract.ngoNumberExist(200)==true);
        assert(nft_contract.registeredNGOs(200)==false);
    }


      //Just register which will go for vote
    function test_acceptRegisterNGoOnVotes()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");


         //maker not have token
        vm.startPrank(address(3));
        vm.expectRevert("Only DAO Token holder can vote.");
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(address(3)) , 0, "Incorrect balance for taker");

        vm.deal(address(3),0.1 ether);

        vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();
        assertEq(daoToken.balanceOf(address(3)) , 1*10**18, "Incorrect balance for taker");

        vm.startPrank(address(3));
        nft_contract.voteAgainstNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(nft_contract.againstVotes(100),1,"No votes available");

        assertEq(daoToken.balanceOf(address(3)) , 0, "Incorrect balance for taker");

        //no Duplicate vote single vote only
         vm.startPrank(address(3));
         vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(address(3)) , 0, "Incorrect balance for taker");
        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);
        console.log("infavor votes",nft_contract.infavourVotes(100));
        console.log("infavor votes",nft_contract.againstVotes(100));

         //confirm by owner of DAO NGo not other as this will fail
        vm.prank(address(3));
        vm.expectRevert();//not allowing 
        nft_contract.confirmRegisteration(100);
       
        assertEq(nft_contract.registeredNGOs(100),false,"nothing available");

        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");

         //confirm by owner of DAO NGo agian to check revert because already verified
        vm.prank(maker);
        vm.expectRevert("NGO already registered.");
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");

        //doesnot exist should revert
         vm.prank(maker);
         vm.expectRevert("NGO registration does not exist.");
        nft_contract.confirmRegisteration(200);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        
    }

      //Just register which will go for vote
    function test_acceptRegisterNGoOnVotes_equal()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);



        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");



        vm.deal(address(3),0.1 ether);

        vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();
        assertEq(daoToken.balanceOf(address(3)) , 1*10**18, "Incorrect balance for taker");

        vm.startPrank(address(3));
        nft_contract.voteAgainstNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(nft_contract.againstVotes(100),1,"No votes available");

        assertEq(daoToken.balanceOf(address(3)) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);
        console.log("infavor votes",nft_contract.infavourVotes(100));
        console.log("infavor votes",nft_contract.againstVotes(100));



        //confirm by owner of DAO NGo
        vm.prank(maker);
        vm.expectRevert("NGO can't registered as majority doesn't want");
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
    }

      function test_acceptRegisterNGoOnVotes_less()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);



        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteAgainstNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.againstVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");



        vm.deal(address(3),0.1 ether);

        vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();
        assertEq(daoToken.balanceOf(address(3)) , 1*10**18, "Incorrect balance for taker");

        vm.startPrank(address(3));
        nft_contract.voteAgainstNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),0,"No votes available");
        assertEq(nft_contract.againstVotes(100),2,"No votes available");

        assertEq(daoToken.balanceOf(address(3)) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);
        console.log("infavor votes",nft_contract.infavourVotes(100));
        console.log("infavor votes",nft_contract.againstVotes(100));



        //confirm by owner of DAO NGo
        vm.prank(maker);
        vm.expectRevert("NGO can't registered as majority doesn't want");
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
    }

    function test_acceptRegisterNGoOnVotes_ontwoDifferentNgo()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();
         vm.startPrank(taker);
        nft_contract.registerationForNGO(200);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);
        
        vm.deal(taker,0.2 ether);
        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.2 ether}(taker,2);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,2* 10**18, "Incorrect balance for taker");
        // assert(address(taker).balance==2 ether);



        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteAgainstNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.againstVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 1*10**18, "check here");

        vm.startPrank(taker);
        nft_contract.voteAgainstNGO(200);
        vm.stopPrank();
        assertEq(nft_contract.againstVotes(200),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        assert(nft_contract.ngoVoters(taker, 100)==true);
        assert(nft_contract.ngoVoters(taker, 200)==true);

    }




    function test_acceptRegisterNGoOnVotes_onlyCreateProposal()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");
    }


    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_revertschecking()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        vm.expectRevert("NGO_NOT_REGISTERED");
        nft_contract.createProposal(1,2,200,"abc",2);
        vm.stopPrank();

        vm.startPrank(taker);
        //Create proposal
        vm.expectRevert("only NGO owner can create the proposal");
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();


        vm.startPrank(maker);
        //Create proposal
        vm.expectRevert("Voting hours must be greater than zero");
        nft_contract.createProposal(0,1,100,"abc",2);
        vm.stopPrank();

         vm.startPrank(maker);
        //Create proposal
        vm.expectRevert("total beneficiary must be greater than zero");
        nft_contract.createProposal(1,0,100,"abc",2);
        vm.stopPrank();

          vm.startPrank(maker);
        //Create proposal
        vm.expectRevert("Max donation must be greater than zero");
        nft_contract.createProposal(1,1,100,"abc",0);
        vm.stopPrank();

        vm.startPrank(address(0));
        vm.expectRevert("only NGO owner can create the proposal");
        nft_contract.createProposal(1,0,100,"abc",2);
        vm.stopPrank();

        vm.startPrank(maker);
        bytes4 selector = bytes4(keccak256("EmptyURI()"));
        //attempting to buy again after first call
        //expect revert or order already executed
        vm.expectRevert(selector);
        nft_contract.createProposal(1,1,100,"",2);
        vm.stopPrank();


        //creating 2 campaigns 
         vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();

         //creating 2 campaigns 
         vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(2,3,100,"abc",2);
        vm.stopPrank();

        assertEq(nft_contract.registeredCampaign(2),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(2),false,"not available");
        assertEq(nft_contract.campaignEndTime(2),block.timestamp+7200 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(2),3,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(2),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),2,"owned one");
        assertEq(nft_contract.tokenURI(2),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),2,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");
    }

    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_updateBeneficiary()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");


        //update beneficiary
        vm.prank(maker);
        nft_contract.updateTotalBeneficary(1,3,100);
        vm.stopPrank();
        assertEq(nft_contract.ngototalBeneficiary(1),3,"here error beneficiary");

        vm.prank(maker);
        vm.expectRevert("NGO_NOT_REGISTERED");
        nft_contract.updateTotalBeneficary(1,3,200);
        vm.stopPrank();
        //update beneficiary
        vm.prank(taker);
        vm.expectRevert("only NGO owner can update beneficiary");
        nft_contract.updateTotalBeneficary(1,3,100);
        vm.stopPrank();

        vm.prank(maker);
        vm.expectRevert("NGO_NOT_REGISTERED");
        nft_contract.updateTotalBeneficary(2,3,200);
        vm.stopPrank();
    }


      function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();


         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==true);
        
        vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         //check function 
         assertEq(nft_contract.isVotingPeriodEnded(1),true);
         vm.expectRevert("CAMPAIGN_ALREADY_ACCEPTED");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
          //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assertEq(address(taker).balance ,1.7 ether,"balance ether");
        //offer
        vm.deal(address(4),0.1 ether);
        vm.startPrank(address(4));
        daoToken.mint{value:0.1 ether}(address(4),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(4)) , 1 * 10**18, "Incorrect balance for taker");

        vm.startPrank(taker);
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(address(4));
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();

    }

     function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAccept_Thenlessvote()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignAgainstVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);



         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         vm.expectRevert("Campaign cannot be accepted as majority does not want");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==false);
    }

    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAccept_ThenEqualVote()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignAgainstVotes(1),1);
        assertEq(nft_contract.campaignFavourVotes(1),1);

        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);
         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         vm.expectRevert("Campaign cannot be accepted as majority does not want");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==false);

    }


      function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAccept_ThenDifferentFavourandAgainstVote()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(2,3,100,"abc",1);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),2,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),2,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.2 ether}(taker,2);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,2 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.7 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.2 ether}(offer,2);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 2 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();

        vm.startPrank(taker);
        nft_contract.voteForCampaign(2);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteAgainstCampaign(2);
        vm.stopPrank();

        assertEq(nft_contract.campaignAgainstVotes(1),1);
        assertEq(nft_contract.campaignFavourVotes(1),1);
        assertEq(nft_contract.campaignFavourVotes(2),1);
        assertEq(nft_contract.campaignAgainstVotes(2),1);


        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);
        

        assertEq(nft_contract.campaignvoters(taker,1),true);
        assertEq(nft_contract.campaignvoters(offer,1),true);
        assertEq(nft_contract.campaignvoters(taker,2),true);
        assertEq(nft_contract.campaignvoters(offer,2),true);



    }

      function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();


         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==true);
        
        vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         //check function 
         assertEq(nft_contract.isVotingPeriodEnded(1),true);
         vm.expectRevert("CAMPAIGN_ALREADY_ACCEPTED");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
          //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assertEq(address(taker).balance ,1.7 ether,"balance ether");
        //offer
        vm.deal(address(4),0.1 ether);
        vm.startPrank(address(4));
        daoToken.mint{value:0.1 ether}(address(4),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(4)) , 1 * 10**18, "Incorrect balance for taker");

        vm.startPrank(taker);
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(address(4));
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();


        vm.startPrank(offer);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 2 ether);
        assertEq(nft_contract.recieved_Donation(1),1 ether);

        vm.startPrank(taker);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();
        assertEq(nft_contract.recieved_Donation(1),2 ether);

        vm.startPrank(taker);
        vm.expectRevert("Max Capaign Ammount Reached");
        nft_contract.makeDonation{value:0.1 ether}(1);
        vm.stopPrank();

        vm.startPrank(taker);
        vm.expectRevert("Insufficient Amount");
        nft_contract.makeDonation{value:0 ether}(1);
        vm.stopPrank();

        assertEq(address(nft_contract).balance,2 ether,"wrong guess");

    }


      function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers_unacceptedCampiagn()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();

        vm.startPrank(offer);
        vm.expectRevert("CAMPAIGN_NOT_ACCEPTED");
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 2 ether);
        assertEq(nft_contract.recieved_Donation(1),0 ether);

        assertEq(address(nft_contract).balance,0 ether,"wrong guess");

    }



    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers_directDonateBeforeProposal()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
       

        vm.startPrank(offer);
        vm.expectRevert("CAMPAIGN_NOT_ACCEPTED");
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 0 ether);
        assertEq(nft_contract.recieved_Donation(1),0 ether);

        assertEq(address(nft_contract).balance,0 ether,"wrong guess");

    }

    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers_voucherCreation()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();


         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==true);
        
        vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         //check function 
         assertEq(nft_contract.isVotingPeriodEnded(1),true);
         vm.expectRevert("CAMPAIGN_ALREADY_ACCEPTED");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
          //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assertEq(address(taker).balance ,1.7 ether,"balance ether");
        //offer
        vm.deal(address(4),0.1 ether);
        vm.startPrank(address(4));
        daoToken.mint{value:0.1 ether}(address(4),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(4)) , 1 * 10**18, "Incorrect balance for taker");

        vm.startPrank(taker);
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(address(4));
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();


        vm.startPrank(offer);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 2 ether);
        assertEq(nft_contract.recieved_Donation(1),1 ether);

        vm.startPrank(taker);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();
        assertEq(nft_contract.recieved_Donation(1),2 ether);
        assertEq(address(nft_contract).balance,2 ether,"wrong guess");


        vm.startPrank(maker);
        nft_contract.createVoucher(address(3), 0.5 ether, "abcd", 1);
        vm.stopPrank();
        
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),1,"no voucher");
        assertEq(nft_contract.priceOfVoucher(address(3),1),0.5 ether,"wrong price");
        assert(nft_contract.balanceOf(address(3))==1);
        vm.startPrank(maker);
        vm.expectRevert("You already have voucher of this campaign");
        nft_contract.createVoucher(address(3), 0.5 ether, "abcd", 1);
        vm.stopPrank();

        //only owner can perform not address 3
        vm.startPrank(address(3));
        vm.expectRevert();
        nft_contract.createVoucher(address(3), 0.5 ether, "abcd", 1);
        vm.stopPrank();
    }


    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers_voucherCreation_notreachedMax()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();


         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==true);
        
        vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         //check function 
         assertEq(nft_contract.isVotingPeriodEnded(1),true);
         vm.expectRevert("CAMPAIGN_ALREADY_ACCEPTED");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
          //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assertEq(address(taker).balance ,1.7 ether,"balance ether");
        //offer
        vm.deal(address(4),0.1 ether);
        vm.startPrank(address(4));
        daoToken.mint{value:0.1 ether}(address(4),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(4)) , 1 * 10**18, "Incorrect balance for taker");

        vm.startPrank(taker);
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(address(4));
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();


        vm.startPrank(offer);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 2 ether);
        assertEq(nft_contract.recieved_Donation(1),1 ether);
        vm.startPrank(maker);
        vm.expectRevert("Campaign has not reached its donation goal");
        nft_contract.createVoucher(address(3), 0.5 ether, "abcd", 1);
        vm.stopPrank();
    }


  function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers_voucherCreation_claimandsendvendor()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();


         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==true);
        
        vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         //check function 
         assertEq(nft_contract.isVotingPeriodEnded(1),true);
         vm.expectRevert("CAMPAIGN_ALREADY_ACCEPTED");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
          //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assertEq(address(taker).balance ,1.7 ether,"balance ether");
        //offer
        vm.deal(address(4),0.1 ether);
        vm.startPrank(address(4));
        daoToken.mint{value:0.1 ether}(address(4),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(4)) , 1 * 10**18, "Incorrect balance for taker");

        vm.startPrank(taker);
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(address(4));
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();


        vm.startPrank(offer);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 2 ether);
        assertEq(nft_contract.recieved_Donation(1),1 ether);

        vm.startPrank(taker);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();
        assertEq(nft_contract.recieved_Donation(1),2 ether);
        assertEq(address(nft_contract).balance,2 ether,"wrong guess");


        vm.startPrank(maker);
        nft_contract.createVoucher(address(3), 0.5 ether, "abcd", 1);
        vm.stopPrank();
        
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),1,"no voucher");
        assertEq(nft_contract.priceOfVoucher(address(3),1),0.5 ether,"wrong price");
        assert(nft_contract.balanceOf(address(3))==1);
       

        vm.startPrank(address(3));
        nft_contract.claimFundsOfBeneficiary(address(3),1,address(4));
        vm.stopPrank();

        assertEq(nft_contract.claimedFunds(1),0.5 ether);
        assertEq(address(address(4)).balance,0.5 ether,"not recieved to vendor");
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),0,"no voucher");
        assertEq(nft_contract.priceOfVoucher(address(3),1),0 ether,"wrong price");

        vm.startPrank(address(3));
        vm.expectRevert("This beneficiary doesn't have a voucher");
        nft_contract.claimFundsOfBeneficiary(address(3),1,address(4));
        vm.stopPrank();

         vm.startPrank(maker);
        nft_contract.createVoucher(address(5), 0 ether, "abcd", 1);
        vm.stopPrank();
        vm.startPrank(address(5));
        vm.expectRevert("This beneficiary doesn't have a price");
        nft_contract.claimFundsOfBeneficiary(address(5),1,address(4));
        vm.stopPrank();
    }



    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers_voucherCreation_claimandsendvendor_exhaustall()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();


         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==true);
        
        vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         //check function 
         assertEq(nft_contract.isVotingPeriodEnded(1),true);
         vm.expectRevert("CAMPAIGN_ALREADY_ACCEPTED");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
          //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assertEq(address(taker).balance ,1.7 ether,"balance ether");
        //offer
        vm.deal(address(4),0.1 ether);
        vm.startPrank(address(4));
        daoToken.mint{value:0.1 ether}(address(4),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(4)) , 1 * 10**18, "Incorrect balance for taker");

        vm.startPrank(taker);
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(address(4));
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();


        vm.startPrank(offer);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 2 ether);
        assertEq(nft_contract.recieved_Donation(1),1 ether);

        vm.startPrank(taker);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();
        assertEq(nft_contract.recieved_Donation(1),2 ether);
        assertEq(address(nft_contract).balance,2 ether,"wrong guess");


        vm.startPrank(maker);
        nft_contract.createVoucher(address(3), 1 ether, "abcd", 1);
        vm.stopPrank();

        vm.startPrank(maker);
        nft_contract.createVoucher(address(5), 1 ether, "abcd", 1);
        vm.stopPrank();
        
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),1,"no voucher");
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(5),1),1,"no voucher");

        assertEq(nft_contract.priceOfVoucher(address(3),1),1 ether,"wrong price");
        assertEq(nft_contract.priceOfVoucher(address(5),1),1 ether,"wrong price");
        assert(nft_contract.balanceOf(address(3))==1);
        assert(nft_contract.balanceOf(address(5))==1);

       

        vm.startPrank(address(3));
        nft_contract.claimFundsOfBeneficiary(address(3),1,address(4));
        vm.stopPrank();

        vm.startPrank(address(5));
        nft_contract.claimFundsOfBeneficiary(address(5),1,address(6));
        vm.stopPrank();

        assertEq(nft_contract.claimedFunds(1),2 ether);
        assertEq(address(address(4)).balance,1 ether,"not recieved to vendor");
        assertEq(address(address(6)).balance,1 ether,"not recieved to vendor");

        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),0,"no voucher");
        assertEq(nft_contract.priceOfVoucher(address(3),1),0 ether,"wrong price");
        
        assertEq(nft_contract.claimedFunds(1),2 ether);
        assertEq(address(address(4)).balance,1 ether,"not recieved to vendor");
        assertEq(address(address(6)).balance,1 ether,"not recieved to vendor");

        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),0,"no voucher");
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(5),1),0,"no voucher");
        assertEq(nft_contract.priceOfVoucher(address(3),1),0 ether,"wrong price");

        assertEq(nft_contract.priceOfVoucher(address(5),1),0 ether,"wrong price");
        vm.startPrank(maker);
        vm.expectRevert("Claimed funds plus voucher price exceed maximum donation for this campaign");
        nft_contract.createVoucher(address(3), 0.25 ether, "abcd", 1);
        vm.stopPrank();
       
    }




    function test_acceptRegisterNGoOnVotes_onlyCreateProposal_VoteOnAcceptThen_Donate_ethers_voucherCreation_claimandsendvendor_exhaustall_Revert()public{
        vm.startPrank(maker);
        nft_contract.registerationForNGO(100);
        vm.stopPrank();

     
        //single owner of ngo
        assert(nft_contract.ngoOwner(100)==maker);
        assert(nft_contract.ngoRegistrationNo(maker)==100);
        assert(nft_contract.ngoNumberExist(100)==true);
        assert(nft_contract.registeredNGOs(100)==false);

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.9 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.9 ether);


        //Now voting
         //taker
        vm.startPrank(taker);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),1,"No votes available");
        assertEq(daoToken.balanceOf(taker) , 0, "Incorrect balance for taker");

        //offer
        vm.startPrank(offer);
        nft_contract.voteForNGO(100);
        vm.stopPrank();
        assertEq(nft_contract.infavourVotes(100),2,"No votes available");
        assertEq(daoToken.balanceOf(offer) , 0, "Incorrect balance for taker");

        //not accepted still after votes
        assert(nft_contract.registeredNGOs(100)==false);


        //confirm by owner of DAO NGo
        vm.prank(maker);
        nft_contract.confirmRegisteration(100);//allowed owner confirmed(contract owner)
        vm.stopPrank();
        assertEq(nft_contract.registeredNGOs(100),true,"nothing available");
        vm.startPrank(maker);
        //Create proposal
        nft_contract.createProposal(1,2,100,"abc",2);
        vm.stopPrank();
        assertEq(nft_contract.registeredCampaign(1),100,"no campaign available");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not available");
        assertEq(nft_contract.campaignEndTime(1),block.timestamp+3600 seconds,"error time");
        assertEq(nft_contract.ngototalBeneficiary(1),2,"error total beneficiary");
        assertEq(nft_contract.maxCampaignDonation(1),2*10**18,"max campaign donation not reached");
        assertEq(nft_contract.balanceOf(maker),1,"owned one");
        assertEq(nft_contract.tokenURI(1),"abc","matche uri");
        assertEq(nft_contract._tokenIds(),1,"checked one");
        assertEq(nft_contract.acceptedCampaigns(1),false,"not accpeted error");

        //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assert(address(taker).balance==1.8 ether);
        //offer
        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.8 ether);


        vm.startPrank(taker);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(offer);
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);
        assertEq(daoToken.balanceOf(taker),0);
        assertEq(daoToken.balanceOf(offer),0);

        vm.startPrank(offer);
        daoToken.mint{value:0.1 ether}(offer,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(offer) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(offer).balance==1.7 ether);

        vm.startPrank(offer);
        vm.expectRevert("ALREADY_VOTED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        assertEq(nft_contract.campaignFavourVotes(1),2);

        vm.deal(address(3),0.1 ether);
         vm.startPrank(address(3));
        daoToken.mint{value:0.1 ether}(address(3),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(3)) , 1 * 10**18, "Incorrect balance for taker");
        assert(address(address(3)).balance==0);

         vm.startPrank(address(3));
         nft_contract.voteAgainstCampaign(1);
         vm.stopPrank();
         assertEq(daoToken.balanceOf(address(3)),0, "Incorrect balance for taker");

         assertEq(nft_contract.campaignAgainstVotes(1),1);

         vm.startPrank(maker);
         vm.expectRevert("Cannot execute during voting period");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();


         vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
    
        assert(nft_contract.acceptedCampaigns(1)==true);
        
        vm.startPrank(maker);
         vm.warp(block.timestamp+3700 seconds);
         //check function 
         assertEq(nft_contract.isVotingPeriodEnded(1),true);
         vm.expectRevert("CAMPAIGN_ALREADY_ACCEPTED");
         nft_contract.confirmAcceptCampaign(1);
         vm.stopPrank();
          //taker
        vm.startPrank(taker);
        daoToken.mint{value:0.1 ether}(taker,1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(taker) ,1 * 10**18, "Incorrect balance for taker");
        assertEq(address(taker).balance ,1.7 ether,"balance ether");
        //offer
        vm.deal(address(4),0.1 ether);
        vm.startPrank(address(4));
        daoToken.mint{value:0.1 ether}(address(4),1);
        vm.stopPrank();

        assertEq(daoToken.balanceOf(address(4)) , 1 * 10**18, "Incorrect balance for taker");

        vm.startPrank(taker);
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteForCampaign(1);
        vm.stopPrank();

        vm.startPrank(address(4));
        vm.expectRevert("VOTING_PERIOD_ENDED");
        nft_contract.voteAgainstCampaign(1);
        vm.stopPrank();


        vm.startPrank(offer);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();

        assertEq(nft_contract.maxCampaignDonation(1), 2 ether);
        assertEq(nft_contract.recieved_Donation(1),1 ether);

        vm.startPrank(taker);
        nft_contract.makeDonation{value:1 ether}(1);
        vm.stopPrank();
        assertEq(nft_contract.recieved_Donation(1),2 ether);
        assertEq(address(nft_contract).balance,2 ether,"wrong guess");


        vm.startPrank(maker);
        nft_contract.createVoucher(address(3), 1 ether, "abcd", 1);
        vm.stopPrank();

        vm.startPrank(maker);
        nft_contract.createVoucher(address(5), 0.9 ether, "abcd", 1);
        vm.stopPrank();
        
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),1,"no voucher");
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(5),1),1,"no voucher");

        assertEq(nft_contract.priceOfVoucher(address(3),1),1 ether,"wrong price");
        assertEq(nft_contract.priceOfVoucher(address(5),1),0.9 ether,"wrong price");
        assert(nft_contract.balanceOf(address(3))==1);
        assert(nft_contract.balanceOf(address(5))==1);

       

        vm.startPrank(address(3));
        nft_contract.claimFundsOfBeneficiary(address(3),1,address(4));
        vm.stopPrank();

        vm.startPrank(address(5));
        nft_contract.claimFundsOfBeneficiary(address(5),1,address(6));
        vm.stopPrank();

        assertEq(nft_contract.claimedFunds(1),1.9 ether);
        assertEq(address(address(4)).balance,1 ether,"not recieved to vendor");
        assertEq(address(address(6)).balance,0.9 ether,"not recieved to vendor");

        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),0,"no voucher");
        assertEq(nft_contract.priceOfVoucher(address(3),1),0 ether,"wrong price");
        
        assertEq(nft_contract.claimedFunds(1),1.9 ether);
        assertEq(address(address(4)).balance,1 ether,"not recieved to vendor");
        assertEq(address(address(6)).balance,0.9 ether,"not recieved to vendor");

        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(3),1),0,"no voucher");
        assertEq(nft_contract.beneficiaryHasVoucherInCampaign(address(5),1),0,"no voucher");
        assertEq(nft_contract.priceOfVoucher(address(3),1),0 ether,"wrong price");

        assertEq(nft_contract.priceOfVoucher(address(5),1),0 ether,"wrong price");
        vm.startPrank(maker);
        vm.expectRevert("Claimed funds plus voucher price exceed maximum donation for this campaign");
        nft_contract.createVoucher(address(3), 0.25 ether, "abcd", 1);
        vm.stopPrank();

         vm.startPrank(maker);
        vm.expectRevert("Claimed funds plus voucher price exceed maximum donation for this campaign");
        nft_contract.createVoucher(address(3), 0.25 ether, "abcd", 1);
        vm.stopPrank();

        vm.startPrank(maker);
        nft_contract.createVoucher(address(7), 0.1 ether, "abcd", 1);
        vm.stopPrank();
        vm.startPrank(address(7));
        nft_contract.claimFundsOfBeneficiary(address(7),1,address(8));
        vm.stopPrank();
         assertEq(nft_contract.claimedFunds(1),2 ether);
        assertEq(address(address(8)).balance,0.1 ether,"not recieved to vendor");
         vm.startPrank(maker);
        vm.expectRevert("Claimed funds plus voucher price exceed maximum donation for this campaign");
        nft_contract.createVoucher(address(3), 0.25 ether, "abcd", 1);
        vm.stopPrank();
    }

    receive() external payable {}



}