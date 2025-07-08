//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test,console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Vm} from "forge-std/Vm.sol";
contract RaffleTest is Test{

event RaffleEntered(address indexed player);
event  WinnerPicked(address indexed winner);

Raffle public raffle;
HelperConfig public helperConfig;

address public PLAYER = makeAddr("player");
uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

uint256 entranceFee;
uint256 interval;
address vrfCoordinator;
bytes32 gasLane;
uint256 subscriptionId;
uint32 callbackGasLimit;


function setUp() external {
    DeployRaffle deployer =new DeployRaffle();
    (raffle,helperConfig) = deployer.deploySmartContract();
    
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    entranceFee = config.entranceFee;
    interval = config.interval;
    vrfCoordinator = config.vrfCoordinator;
    subscriptionId = raffle.getSubscriptionId();
    gasLane = config.gasLane;
    callbackGasLimit = config.callbackGasLimit;
    console.log("Subscription ID:",subscriptionId);
    vm.deal(PLAYER,STARTING_PLAYER_BALANCE);
}

modifier raffleEntered(){
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();

    vm.warp(block.timestamp  + interval +1);
    vm.roll(block.number + 1);
    _;
}

function testRaffleInitializeWithOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    // assert(uint256(raffle.getRaffleState()) == 0);
}

function testRaffleRevertWhenYouDontPayEnough() public {
    vm.prank(PLAYER);
    vm.expectRevert(Raffle.Raffle__NeedMoreEthtoEnter.selector);
    raffle.enterRaffle();
}

function testPlayerisAddedInRaffle() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    address playerRecorded = raffle.getPlayer(0);
    assertEq(playerRecorded,PLAYER);
}

function testEnteringRaffleEmitEvent() public {
    vm.prank(PLAYER);
    vm.expectEmit(true,false,false,false,address(raffle));
    emit RaffleEntered(PLAYER);

    raffle.enterRaffle{value:entranceFee}();
}

function testRaffleRevertWhenNotOpen() public raffleEntered {
    
    raffle.performUpkeep("");
    vm.expectRevert(Raffle.Raffle__raffleNotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
}

function testCheckUpKeepReturnsFalseIfNotEnoughBalance() public {
    //arrange
    vm.prank(PLAYER);
    
    //act
    vm.warp(block.timestamp  + interval +1);
    vm.roll(block.number + 1);
    (bool upKeepNeeded,) = raffle.checkUpkeep("");

    //assert
    assert(!upKeepNeeded);
}

function testCheckUpKeepReturnsFalseIfraffleisNotOpen() public raffleEntered{
    //arrange
    raffle.performUpkeep("");

    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    //assert
    assert(!upkeepNeeded);
}
function testPerformUpKeepRevertIfraffleisNotOpen() public raffleEntered{
    //arrange
    raffle.performUpkeep("");
    uint256 currentBalance=entranceFee;
    uint256 numberOfPlayers=1;
    Raffle.RaffleState rState = raffle.getRaffleState();
    vm.expectRevert(abi.encodeWithSelector(
        Raffle.Raffle_UpkeepNeed.selector,
        currentBalance,
        numberOfPlayers,
        rState
    ));
    raffle.performUpkeep("");
}

function testContractBalanceIsZeroAfterWinnerisPicked() public {
    //arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    for(uint i=2;i<=10;i++){
        address newPlayer = makeAddr(string.concat("player", Strings.toString(i)));
        vm.deal(newPlayer,STARTING_PLAYER_BALANCE);

        vm.prank(newPlayer);
        raffle.enterRaffle{value:entranceFee}();
    }
    //act
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    uint256 reqId=raffle.performUpkeep("");
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        reqId,
        address(raffle)
    );
    //assert
    assert(address(raffle).balance ==0);
}

 function testParticipantArrayIsEmptyAfterWinnerisPicked() public raffleEntered{
    //arrange 
    //act
    uint256 reqId=raffle.performUpkeep("");
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        reqId,
        address(raffle)
    );
    //assert
    assert(raffle.getNumberOfPlayers()==0);
 } 

 function testRaffleRevertIfNoWinnerYet() public {
    //arrange
    vm.prank(PLAYER); 
    vm.expectRevert(Raffle.NoWinnerYet.selector);

    raffle.getRecentWinner();
 }

 function testRaffleSendMoneyToWinner() public {
    //arrange 
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();

    for(uint i=2;i<=10;i++){
        address newPlayer = makeAddr(string.concat("player", Strings.toString(i)));
        vm.deal(newPlayer,STARTING_PLAYER_BALANCE);

        vm.prank(newPlayer);
        raffle.enterRaffle{value:entranceFee}();
    }
    //act
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    uint256 reqId=raffle.performUpkeep("");
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        reqId,
        address(raffle)
    );
    address winner = raffle.getRecentWinner();
    uint256 winnerBalance = winner.balance;
    assert(winnerBalance ==(STARTING_PLAYER_BALANCE-entranceFee)+(entranceFee*10));    
 }

 function testPerformUpKeepChangeRaffleStateAndEmitRequestId() public raffleEntered{
    //act
    vm.recordLogs();
    raffle.performUpkeep("");

    Vm.Log[] memory entries = vm.getRecordedLogs();
    
    bytes32 requestId = entries[1].topics[1];
    Raffle.RaffleState rState = raffle.getRaffleState();

    assert(uint256(rState)==1);
    assert(uint256(requestId)>0);
 }
}

