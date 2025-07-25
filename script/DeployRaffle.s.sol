//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "./Interactions.s.sol";
contract DeployRaffle is Script{
    function run() public {
        deploySmartContract();
    }
    function deploySmartContract() public returns(Raffle,HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0){
            //Creating a new subscription
            CreateSubscription createSubscription  = new CreateSubscription();
            (config.subscriptionId,config.vrfCoordinator)  =  
                createSubscription.createSubscription(config.vrfCoordinator);

            //Funding the subscription
            FundSubscription fundSubscription =new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link
            );

        }
        vm.startBroadcast();
        Raffle raffle =new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        //adding consumer 
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId
        );
        return (raffle,helperConfig);
    }
    
}