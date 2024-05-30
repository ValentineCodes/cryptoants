// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address owner, uint256 amount);
  event AntCreated(address owner, uint256 antId, uint256 ovipositionPeriod);
  event AntSold(address owner, uint256 antId, uint256 price);
  event PricesUpdated(uint256 newEggPrice, uint256 newAntPrice);
  event EggsLaid(address owner, uint256 antId, uint256 eggsFertilized, uint256 eggsLaid, bool isAntDead);
  event OvipositionRequested(uint256 requestId, uint256 paid);
  event OvipositionRequestFulfilled(uint256 requestId, uint256 paid);
  event OvipositionPeriodReset(uint256 antId, uint256 ovipositionPeriod);

  struct Ant {
    address owner;
    uint256 id;
  }
  struct OvipositionRequest {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    Ant ant;
  }

  /**
    @notice Mints {_amount} eggs to msg.sender. 1 Egg == `s_eggPrice`
    @param _amount Amount of eggs to mint
   */
  function buyEggs(uint256 _amount) external payable;

  /**
    @notice Creates an ant with an egg. 
            Burns the egg and mints an ant to msg.sender
    @return _antId ID of an created
   */
  function createAnt() external returns (uint256 _antId);

  /**
    @notice Sell an ant for `s_antPrice`. Ant is squashed but can be reincarnated.
    @param _antId ID of ant to sell
   */
  function sellAnt(uint256 _antId) external;

  /**
    @notice Starts oviposition if oviposition period has been reached. 
            Ants can lay at least One egg during the oviposition period. 
            The more eggs are laid, the higher the chances of dying
    @dev Requests random numbers from Chainlink to determine number of eggs to lay and the dying chance
    @param _antId ID of ant to lay eggs
    @return requestId Request ID of random number request from Chainlink
   */
  function startOviposition(uint256 _antId) external returns (uint256 requestId);

  /**
    @notice Updates egg and ant price. 
            Ant price must always be less than egg price
    @dev Only the governor can call this
    @param _newEggPrice New egg price
    @param _newAntPrice New ant price
   */
  function updatePrices(uint256 _newEggPrice, uint256 _newAntPrice) external;

  /**
  @notice Withdraws ether
  @dev Only the governor can call this
  @param _recipient Address of ether receiver
  @param _amount Amount to withdraw
  */
  function withdrawEther(address payable _recipient, uint256 _amount) external;

  /**
    @notice Withdraws LINK token
    @dev Only the governor can call this
    @param _recipient Address of token receiver
    @param _amount Amount to withdraw
   */
  function withdrawLink(address _recipient, uint256 _amount) external;

  /// @notice Gets egg price
  function getEggPrice() external view returns (uint256);

  /// @notice Gets ant price
  function getAntPrice() external view returns (uint256);

  /// @notice Gets number of ants created
  function getAntsCreated() external view returns (uint256);

  /**
    @notice Gets oviposition period of ant
    @param _antId ID of ant
   */
  function getOvipositionPeriod(uint256 _antId) external view returns (uint256 ovipositionPeriod);

  /**
    @notice Gets oviposition request
    @param _requestId Request ID from Chainlink VRf
   */
  function getOvipositionRequest(uint256 _requestId) external view returns (OvipositionRequest memory);
}
