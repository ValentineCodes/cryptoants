// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/token/ERC721/ERC721.sol';
import {IEgg} from './interfaces/IEgg.sol';
import {ICryptoAnts} from './interfaces/ICryptoAnts.sol';

contract CryptoAnts is ICryptoAnts, ERC721 {
  IEgg public immutable eggs;
  uint256 public s_eggPrice = 0.01 ether;
  uint256 public s_antsCreated = 0;

  constructor(address _eggs) ERC721('Crypto Ants', 'ANTS') {
    eggs = IEgg(_eggs);
  }

  function buyEggs(uint256 _amount) external payable {
    if (_amount == 0) revert ZeroAmount();

    if ((_amount * s_eggPrice) != msg.value) revert WrongEtherSent();

    eggs.mint(msg.sender, _amount);

    emit EggsBought(msg.sender, _amount);
  }

  function createAnt() external {
    if (eggs.balanceOf(msg.sender) < 1) revert NoEggs();
    uint256 _antId = ++s_antsCreated;

    if (_ownerOf(_antId) != address(0)) revert AlreadyExists();

    eggs.burn(msg.sender, 1);

    _mint(msg.sender, _antId);

    emit AntCreated(msg.sender, _antId);
  }

  function sellAnt(uint256 _antId) external {
    if (_ownerOf(_antId) != msg.sender) revert NotAntOwner();

    _burn(_antId);

    // q Should ant price be fixed or determined by governance but still less than egg price?
    (bool success,) = msg.sender.call{value: 0.004 ether}('');
    if (!success) revert TransferFailed();

    emit AntSold(msg.sender, _antId);
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getAntsCreated() public view returns (uint256) {
    return s_antsCreated;
  }
}
