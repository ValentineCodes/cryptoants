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

  struct Ant {
    address owner;
    uint256 id;
  }
  struct OvipositionRequest {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    Ant ant;
  }

  function buyEggs(uint256) external payable;

  function createAnt() external;

  function sellAnt(uint256 _antId) external;

  function startOviposition(uint256 _antId) external returns (uint256 requestId);

  function updatePrices(uint256 newEggPrice, uint256 newAntPrice) external;

  function withdrawLink(address _receiver, uint256 _amount) external;

  function getEggPrice() external view returns (uint256);

  function getAntPrice() external view returns (uint256);

  function getAntsCreated() external view returns (uint256);

  function getOvipositionPeriod(uint256 _antId) external view returns (uint256 ovipositionPeriod);

  function getOvipositionRequest(uint256 requestId) external view returns (OvipositionRequest memory ovipositionRequest);
}
