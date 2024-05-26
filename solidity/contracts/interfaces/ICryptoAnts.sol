// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address, uint256);
  event AntSold(address seller, uint256 antId);

  function buyEggs(uint256) external payable;

  function createAnt() external;

  error NoEggs();

  event AntSold();

  error NoZeroAddress();

  event AntCreated();

  error AlreadyExists();
  error WrongEtherSent();

  error ZeroAmount();

  error NotAntOwner();

  error TransferFailed();
}
