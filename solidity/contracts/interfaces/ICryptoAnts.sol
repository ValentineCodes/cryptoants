// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address owner, uint256 amount);
  event AntCreated(address owner, uint256 antId);
  event AntSold(address owner, uint256 antId);
  event PricesUpdated(uint256 newEggPrice, uint256 newAntPrice);
  event EggsLayed(address owner, uint256 antId, uint256 eggsLayed, bool isAntDead);
  event OvipositionRequested(uint256 requestId, uint256 paid);
  event OvipositionRequestFulfilled(uint256 requestId, uint256 paid);

  function buyEggs(uint256) external payable;

  function createAnt() external;

  error NoEggs();

  event AntSold();

  error ZeroAddress();

  event AntCreated();

  error AlreadyExists();
  error WrongEtherSent();

  error ZeroAmount();

  error NotAntOwner();

  error TransferFailed();

  error AntPriceMustBeLessThanEggPrice();

  error RequestNotFound(uint256 requestId);

  error PreOvipositionPeriod();

  error InsufficientFunds(uint256 balance, uint256 paid);
}
