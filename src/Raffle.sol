// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title A sample Raffle contrcat
 * @author Adarsh Rai
 * @notice this contract is for creating sample raffle
 * @dev Implement Chainlink VRFv2.5
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__NeedMoreEthtoEnter();
    error Raffle__EnoughTimeNotPassed();
    error TransferFailed();
    error Raffle__raffleNotOpen();
    error Raffle_UpkeepNeed(uint256 balance,uint256 playersCount,RaffleState raffleState);

    /**
     * Type Declaration
     */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    /**
     * State variable
     */

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 3;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event  WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        //@dev the duration of lottery in seconds
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        /**Checks */
        if (msg.value < i_entranceFee) {
            revert Raffle__NeedMoreEthtoEnter();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__raffleNotOpen();
        }

        /**Effects */
        s_players.push(payable(msg.sender));

        /**Interactions */
        emit RaffleEntered(msg.sender);
    }
    //1.Get a Random Number
    //2. Pick a winner (randomly)
    //3. automate this process

    //what is needed to call performUpkeep?
    /**
     * @dev these are the conditions that must be met to call performUpkeep
     * 1.Enough time has passed between raffle runs
     * 2.The raffle is in an open state
     * 3. The contract has Eth
     * 4. The subscription is funded with Chainlink VRF
     * @return upkeepNeeded - true if it is time to restart the raffle
     * return ignored
     */

    function checkUpkeep(bytes memory /*checkData*/) 
    public
    view 
    returns (bool upkeepNeeded, bytes memory /*performData*/){
        bool EnoughTimePassed =  ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool isOpen  = s_raffleState == RaffleState.OPEN;
        bool enoughBalance = address(this).balance>0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = EnoughTimePassed && isOpen && enoughBalance && hasPlayers;
        return (upkeepNeeded, hex"");
    } 

    function performUpkeep(bytes calldata /*performData*/) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle_UpkeepNeed(address(this).balance,s_players.length,s_raffleState);
        }
        s_raffleState = RaffleState.CALCULATING;
        //here we created struct request which will be passed in requestRandomWords function
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

         s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal virtual override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);
        
        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * Getter  Function
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
