//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
contract CodeConstants{
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script{

    error HelperConfig__InvalidChainId(uint256 chainId);

struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
}
/*VRF Mock Values*/
uint96 public constant MOCK_BASE_FEE = 0.25 ether;
uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
//LINK /Eth prices
uint256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
NetworkConfig public localNetworkConfig;
mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor(){
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigWithChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator!=address(0)){
            return networkConfigs[chainId];
        } else if(chainId == LOCAL_CHAIN_ID){
          return getOrCreateLocalNetworkConfig();
        }
        else{
            revert HelperConfig__InvalidChainId(chainId);
        }
    }

    function getConfig() public returns(NetworkConfig memory){
        return getConfigWithChainId(block.chainid);
    }
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee:0.01 ether,
            interval: 60 seconds,
            vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId:106404784965618611810312823985782189410831862953944559113579139245262010875652,
            callbackGasLimit: 500000,
            link:0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreateLocalNetworkConfig() public returns(NetworkConfig memory){
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        //Deploy the local network config
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator_mock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            (int256)(MOCK_WEI_PER_UNIT_LINK)
        );
        LinkToken linktoken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 60 seconds,
            vrfCoordinator: address(vrfCoordinator_mock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,// Local networks do not use subscriptions
            callbackGasLimit: 500000,
            link:address(linktoken)
        });
        return localNetworkConfig;
    }
}