// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address, uint256);

  function notLocked() external view returns (bool);

  function buyEggs(uint256) external payable;

  error NoEggs();

  event AntSold();

  error NoZeroAddress();

  event AntCreated();

  error AlreadyExists();
  error WrongEtherSent();
}
