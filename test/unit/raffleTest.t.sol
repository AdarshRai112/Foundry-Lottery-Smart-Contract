//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

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
    gasLane = config.gasLane;
    subscriptionId = config.subscriptionId;
    callbackGasLimit = config.callbackGasLimit;
    
    vm.deal(PLAYER,STARTING_PLAYER_BALANCE);
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

function testRaffleRevertWhenNotOpen() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();

    vm.warp(block.timestamp  + interval +1);
    vm.roll(block.number + 1);

    raffle.performUpkeep("");
    vm.expectRevert(Raffle.Raffle__raffleNotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
}
}

