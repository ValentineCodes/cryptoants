// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Script} from 'forge-std/Script.sol';
import {ICryptoAnts, CryptoAnts} from 'contracts/CryptoAnts.sol';
import {IEgg, Egg} from 'contracts/Egg.sol';

contract Deploy is Script {
  ICryptoAnts internal _cryptoAnts;
  address deployer;
  IEgg internal _eggs;

  function run() external {
    deployer = vm.rememberKey(vm.envUint('DEPLOYER_PRIVATE_KEY'));
    vm.startBroadcast(deployer);
    _eggs = new Egg(address(_cryptoAnts));
    _cryptoAnts = new CryptoAnts(address(_eggs));
    vm.stopBroadcast();
  }
}
