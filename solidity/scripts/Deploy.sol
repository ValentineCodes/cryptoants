// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from 'forge-std/Script.sol';
import {GovernanceToken} from "contracts/governance/GovernanceToken.sol";
import {GovernanceTimeLock} from "contracts/governance/GovernanceTimeLock.sol";
import {GovernorContract} from "contracts/governance/GovernorContract.sol";
import {CryptoAnts} from "contracts/tokens/CryptoAnts.sol";
import {Egg} from "contracts/tokens/Egg.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

error InvalidPrivateKey(string);
error TransferFailed();
contract Deploy is Script {
  address deployer;

  address private constant LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
  uint256 private constant AMOUNT_TO_FUND_ANTS = 5;

  uint256 constant MIN_DELAY = 1;
  address[] proposers;
  address[] executors;

  function run() external {
    deployer = vm.rememberKey(vm.envUint('DEPLOYER_PRIVATE_KEY'));
    if(deployer == address(0)) revert InvalidPrivateKey("You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env");

    vm.startBroadcast(deployer);

    GovernanceToken governanceToken = new GovernanceToken();

    governanceToken.delegate(deployer);

    GovernanceTimeLock governanceTimeLock = new GovernanceTimeLock(MIN_DELAY, proposers, executors);

    GovernorContract governorContract = new GovernorContract(governanceToken, governanceTimeLock);

    bytes32 proposerRole = governanceTimeLock.PROPOSER_ROLE();
    bytes32 executorRole = governanceTimeLock.EXECUTOR_ROLE();
    bytes32 timelockAdminRole = governanceTimeLock.DEFAULT_ADMIN_ROLE();

    governanceTimeLock.grantRole(proposerRole, address(governorContract));
    governanceTimeLock.grantRole(executorRole, address(0));
    governanceTimeLock.revokeRole(timelockAdminRole, deployer);

    Egg egg = new Egg();

    CryptoAnts ants = new CryptoAnts(address(egg), address(governanceTimeLock));

    LinkTokenInterface link = LinkTokenInterface(LINK_ADDRESS);

    if(link.transfer(address(ants), AMOUNT_TO_FUND_ANTS) == false) revert TransferFailed();

    egg.initialize(address(ants));

    vm.stopBroadcast();
  }
}
