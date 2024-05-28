// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from 'forge-std/Test.sol';
import {TestUtils} from 'test/TestUtils.sol';
import {console} from 'forge-std/console.sol';
import {GovernanceToken} from "contracts/governance/GovernanceToken.sol";
import {GovernanceTimeLock} from "contracts/governance/GovernanceTimeLock.sol";
import {GovernorContract} from "contracts/governance/GovernorContract.sol";
import {CryptoAnts} from "contracts/tokens/CryptoAnts.sol";
import {Egg} from "contracts/tokens/Egg.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

error InvalidPrivateKey(string);
error TransferFailed();
error Egg__OnlyAntsContractCanCallThis();
error ERC721NonexistentToken(uint256 tokenId);

contract E2ECryptoAnts is Test, TestUtils {
  uint256 internal constant FORK_BLOCK = 5_993_582;

  address internal deployer;
  address internal alice = makeAddr('alice');
  address internal bob = makeAddr('bob');

  address private constant LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
  uint256 private constant AMOUNT_TO_FUND_ANTS = 5;

  uint256 constant MIN_DELAY = 1;
  address[] proposers;
  address[] executors;

  GovernanceToken internal governanceToken;
  GovernanceTimeLock internal governanceTimeLock;
  GovernorContract internal governorContract;

  Egg internal egg;
  CryptoAnts internal ants;
  LinkTokenInterface internal link;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('sepolia'), FORK_BLOCK);
    
    deployer = vm.rememberKey(vm.envUint('DEPLOYER_PRIVATE_KEY'));
    if(deployer == address(0)) revert InvalidPrivateKey("You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env");

    vm.prank(deployer);
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

    egg = new Egg();

    ants = new CryptoAnts(address(egg), address(governanceTimeLock));

    link = LinkTokenInterface(LINK_ADDRESS);

    vm.prank(deployer);
    if(link.transfer(address(ants), AMOUNT_TO_FUND_ANTS) == false) revert TransferFailed();

    egg.initialize(address(ants));
  }

  function testOnlyAllowCryptoAntsToMintEggs() public {
    vm.startPrank(deployer);
    vm.expectRevert(Egg__OnlyAntsContractCanCallThis.selector);

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
  function testBeAbleToCreate100AntsWithOnlyOneInitialEgg() public {}

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
