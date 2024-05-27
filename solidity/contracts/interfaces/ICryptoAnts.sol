// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address owner, uint256 amount);
  event AntCreated(address owner, uint256 antId);
  event AntSold(address owner, uint256 antId);
  event PricesUpdated(uint256 newEggPrice, uint256 newAntPrice);

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

  error AntPriceMustBeLessThanEggPrice();

  error RequestNotFound();

  error PreOvipositionPeriod();
}
