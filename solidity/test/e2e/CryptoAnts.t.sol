// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from 'forge-std/Test.sol';
import {Vm} from "forge-std/Vm.sol";
import {TestUtils} from 'test/TestUtils.sol';
import {console} from 'forge-std/console.sol';
import {GovernanceToken} from "contracts/governance/GovernanceToken.sol";
import {GovernanceTimeLock} from "contracts/governance/GovernanceTimeLock.sol";
import {GovernorContract} from "contracts/governance/GovernorContract.sol";
import {CryptoAnts} from "contracts/tokens/CryptoAnts.sol";
import {Egg} from "contracts/tokens/Egg.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

// mocks
import {VRFCoordinatorV2Mock} from "contracts/mocks/VRFCoordinatorV2Mock.sol";
import {MockV3Aggregator} from "contracts/mocks/MockV3Aggregator.sol";
import {LinkToken} from "contracts/mocks/LinkToken.sol";
import {VRFV2Wrapper} from "contracts/mocks/VRFV2Wrapper.sol";

error InvalidPrivateKey(string);
error TransferFailed();
error OnlyAntsContractCanCallThis();
error ERC721NonexistentToken(uint256 tokenId);

contract E2ECryptoAnts is Test, TestUtils {
  uint256 internal constant FORK_BLOCK = 5_993_582;

  address internal deployer;
  address internal alice = makeAddr('alice');
  address internal bob = makeAddr('bob');

  uint256 private constant AMOUNT_TO_FUND_ANTS = 10 ether;

  uint256 constant MIN_DELAY = 1;
  address[] proposers;
  address[] executors;

  uint256 private constant NEW_EGG_PRICE = 0.05 ether;
  uint256 private constant NEW_ANT_PRICE = 0.01 ether;

  GovernanceToken internal governanceToken;
  GovernanceTimeLock internal governanceTimeLock;
  GovernorContract internal governorContract;

  VRFCoordinatorV2Mock vrfCoordinatorV2Mock;
  VRFV2Wrapper vrfV2Wrapper;

  Egg internal egg;
  CryptoAnts internal ants;
  LinkTokenInterface internal link;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('sepolia'), FORK_BLOCK);
    
    deployer = vm.rememberKey(vm.envUint('DEPLOYER_PRIVATE_KEY'));
    if(deployer == address(0)) revert InvalidPrivateKey("You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env");

    vm.startPrank(deployer);

    governanceToken = new GovernanceToken();

    governanceToken.delegate(deployer);

    governanceTimeLock = new GovernanceTimeLock(MIN_DELAY, proposers, executors);

    governorContract = new GovernorContract(governanceToken, governanceTimeLock);

    bytes32 proposerRole = governanceTimeLock.PROPOSER_ROLE();
    bytes32 executorRole = governanceTimeLock.EXECUTOR_ROLE();
    bytes32 timelockAdminRole = governanceTimeLock.DEFAULT_ADMIN_ROLE();

    governanceTimeLock.grantRole(proposerRole, address(governorContract));
    governanceTimeLock.grantRole(executorRole, address(0));
    governanceTimeLock.revokeRole(timelockAdminRole, deployer);

    // deploy mocks

    vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);

    MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(18, 3000000000000000);

    LinkToken linkToken = new LinkToken();

    vrfV2Wrapper = new VRFV2Wrapper(address(linkToken), address(mockV3Aggregator), address(vrfCoordinatorV2Mock));

    vrfV2Wrapper.setConfig(
      60000,
      52000,
      10,
      0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc,
      10
    );

    vrfCoordinatorV2Mock.fundSubscription(1, 10 ether);

    egg = new Egg();

    ants = new CryptoAnts(address(egg), address(governanceTimeLock), address(linkToken), address(vrfV2Wrapper));

    if(linkToken.transfer(address(ants), AMOUNT_TO_FUND_ANTS) == false) revert TransferFailed();

    egg.initialize(address(ants));

    vm.stopPrank();
  }

  function testOnlyAllowCryptoAntsToMintEggs() public {
    vm.startPrank(deployer);
    vm.expectRevert(OnlyAntsContractCanCallThis.selector);

    egg.mint(alice, 1);

    vm.stopPrank();
  }
  function testBuyAnEggAndCreateNewAnt() public {
    createAnt();
  }
  function testSendFundsToTheUserWhoSellsAnts() public {
    createAnt();

    vm.startPrank(deployer);

    uint256 ethBalance = deployer.balance;
    uint256 antId = 1;
    ants.sellAnt(antId);

    assertEq(ants.balanceOf(deployer), 0);
    assertEq(deployer.balance, ethBalance + ants.getAntPrice());

    vm.stopPrank();
  }
  function testBurnTheAntAfterTheUserSellsIt() public {
    createAnt();

    vm.startPrank(deployer);

    uint256 antId = 1;
    ants.sellAnt(antId);

    bytes4 errorSelector = bytes4(keccak256("ERC721NonexistentToken(uint256)"));
    vm.expectRevert(abi.encodeWithSelector(errorSelector, antId));
    ants.ownerOf(antId);

    vm.stopPrank();
  }
  function testReincarnation() public {
    createAnt();

    vm.startPrank(deployer);

    uint256 antId = 1;
    ants.sellAnt(antId);
    ants.buyEggs{value: ants.getEggPrice()}(1);
    ants.createAnt();

    assertEq(ants.ownerOf(antId), deployer);

    vm.stopPrank();
  }

  function testOviposition() public {
    createAnt();

    uint256 _antId = 1;

    skip(10 minutes);

    vm.startPrank(deployer);

    ants.buyEggs{value: ants.getEggPrice()}(1);

    uint256 prevEggsBalance = egg.balanceOf(deployer);

    vm.recordLogs();

    uint256 requestId = ants.initOviposition(_antId);

    vrfCoordinatorV2Mock.fulfillRandomWords(requestId, address(vrfV2Wrapper));

    Vm.Log[] memory entries = vm.getRecordedLogs();

    (
      /* address owner */,
      uint256 antId,
      uint256 eggsLayed,
      bool isAntDead
    ) = abi.decode(entries[7].data, (address, uint256, uint256, bool));

    if(isAntDead){
      bytes4 errorSelector = bytes4(keccak256("ERC721NonexistentToken(uint256)"));
      vm.expectRevert(abi.encodeWithSelector(errorSelector, antId));
      ants.ownerOf(antId);
      console.log("Ant died but layed ", eggsLayed);
    } else {
      console.log("Ant layed ", eggsLayed);
    }
    assertEq(egg.balanceOf(deployer), prevEggsBalance + eggsLayed);

    vm.stopPrank();
  }
  function testCanUpdatePrices() public {
    vm.startPrank(deployer);

    address[] memory targets = new address[](1);
    targets[0] = address(ants);

    uint256[] memory values = new uint256[](1);
    values[0] = 0;

    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encodePacked(CryptoAnts.updatePrices.selector, abi.encode(NEW_EGG_PRICE, NEW_ANT_PRICE));

    string memory proposalDescription = "Update prices";

    uint256 proposalId = governorContract.propose(
      targets,
      values,
      calldatas,
      proposalDescription
    );

    uint256 votingDelay = governorContract.votingDelay();
    uint256 votingPeriod = governorContract.votingPeriod();

    vm.roll(block.number + votingDelay + 1);
    vm.warp(block.timestamp + ((votingDelay + 1) * 12));

    governorContract.castVoteWithReason(proposalId, 1, "Greed!");

    vm.roll(block.number + votingPeriod + 1);
    vm.warp(block.timestamp + ((votingPeriod + 1) * 12));

    governorContract.queue(
      targets,
      values,
      calldatas,
      keccak256(bytes(proposalDescription))
    );

    skip(1);

    governorContract.execute(
      targets,
      values,
      calldatas,
      keccak256(bytes(proposalDescription))
    );

    assertEq(ants.getEggPrice(), NEW_EGG_PRICE);
    assertEq(ants.getAntPrice(), NEW_ANT_PRICE);

    vm.stopPrank();
  }
  // function testBeAbleToCreate100AntsWithOnlyOneInitialEgg() public {}

  function createAnt() internal {
    vm.startPrank(deployer);

      // Buy an egg
      ants.buyEggs{value: ants.getEggPrice()}(1);

      assertEq(egg.balanceOf(deployer), 1);
      assertEq(address(ants).balance, ants.getEggPrice());

      // Create ant
      ants.createAnt();

      assertEq(ants.balanceOf(deployer), 1);
      assertEq(egg.balanceOf(deployer), 0);
      assertEq(ants.getOvipositionPeriod(1), block.timestamp + 10 minutes);

    vm.stopPrank();
  }
}
