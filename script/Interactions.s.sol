//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script,console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
contract CreateSubscription is Script{

    function createSubscriptionUsingConfig() public returns(uint256,address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId,) = createSubscription(vrfCordinator);
        return (subId,vrfCordinator);
        }

    function createSubscription(address vrfCoordinator) public returns(uint256,address) {
        console.log("Creating subscription of chain ID:",block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID:", subId);
        console.log("Please update the subscription ID in the HelperConfig contract.");

        return (subId,vrfCoordinator);
    }
    function run() external {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script,CodeConstants {
    uint96 public constant FUND_AMOUNT = 3 ether;
    uint96 public constant FUND_AMOUNT_FOR_MOCK = 70 ether;
    function fundSubscriptionUsingConfig() public {
         HelperConfig helperConfig = new HelperConfig();
        address vrfCordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId= helperConfig.getConfig().subscriptionId;
        address linktoken  = helperConfig.getConfig().link;
        fundSubscription(vrfCordinator,subId,linktoken);
    }

    function fundSubscription(address vrfCordinator,uint256 subId , address linktoken) public {
        console.log("Funding subscription :",subId);
        console.log("Using VRF Coordinator:", vrfCordinator);
        console.log("On Chain Id:",block.chainid);

        if(block.chainid==LOCAL_CHAIN_ID){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCordinator).fundSubscription(
                subId,
                FUND_AMOUNT_FOR_MOCK
            );
            vm.stopBroadcast();
        }
        else{
            vm.startBroadcast();
            LinkToken(linktoken).transferAndCall(
                vrfCordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }
    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script{
    function addConsumerUsingConfig(address mostRecentlyDeployedContract) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId  = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        addConsumer(mostRecentlyDeployedContract,vrfCoordinator,subId);
    } 

    function addConsumer(address mostRecentlyDeployedContract,address vrfCoordinator,uint256 subId) public {
        console.log("adding consumer contract:", mostRecentlyDeployedContract);
        console.log("Using VRF Coordinator:", vrfCoordinator);
        console.log("On Chain Id:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            mostRecentlyDeployedContract
        );
        vm.stopBroadcast();
        console.log("Consumer added successfully to subscription ID:", subId);
    }
    function run() external {
        address mostRecentlyDeployedContract = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployedContract);
    }
}