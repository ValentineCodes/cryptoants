// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ConfirmedOwner} from '@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol';
import {VRFV2WrapperConsumerBase} from '@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol';
import {IEgg} from '../interfaces/IEgg.sol';
import {ICryptoAnts} from '../interfaces/ICryptoAnts.sol';

/**
 * @author ValentineOrga.eth
 *   @title  CryptoAnts
 *   @dev    This contract is the main entry point for all user interactions
 *           Users will interact with this contract to buy eggs, create and sell ants, and lay eggs
 *           Governance can update prices and withdraw link tokens
 */
contract CryptoAnts is ICryptoAnts, ERC721, VRFV2WrapperConsumerBase, ConfirmedOwner {
  IEgg private immutable eggs;
  LinkTokenInterface private immutable linkToken;

  uint256 private s_eggPrice = 0.01 ether;
  uint256 private s_antPrice = 0.004 ether;
  uint256 private s_antsCreated;

  // squashed ants to reincarnate
  uint256[] private s_antsToReincarnate;

  // maximum number of eggs an ant can lay during oviposition
  uint256 public constant MAX_EGGS_FERTILIZED = 10;

  // how long from ant creation before ant can lay eggs
  uint256 public constant PREOVIPOSITION_PERIOD = 10 minutes;

  // how long oviposition can wait before reset
  uint256 public constant OVIPOSITION_DEADLINE = 3 days;

  // oviposition period for each ant
  mapping(uint256 antId => uint256 ovipositionPeriod) private s_ovipositionPeriod;

  // oviposition requests
  mapping(uint256 requestId => OvipositionRequest ovipositionRequest) private s_ovipositionRequests;

  // chainlink vrf config
  uint32 private constant CALLBACK_GAS_LIMIT = 300_000;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 2;

  constructor(
    address _eggs,
    address _governance,
    address _linkAddress,
    address _wrapperAddress
  ) ERC721('Crypto Ants', 'ANTS') ConfirmedOwner(_governance) VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress) {
    eggs = IEgg(_eggs);
    linkToken = LinkTokenInterface(_linkAddress);
  }

  /**
   * @notice Mints {_amount} eggs to msg.sender. 1 Egg == `s_eggPrice`
   *   @param _amount Amount of eggs to mint
   */
  function buyEggs(uint256 _amount) external payable {
    if (_amount == 0) revert ZeroAmount();
    if ((_amount * s_eggPrice) != msg.value) revert WrongEtherSent();

    eggs.mint(msg.sender, _amount);

    emit EggsBought(msg.sender, _amount);
  }

  /**
   * @notice Creates an ant with an egg. Burns the egg and mints an ant to msg.sender
   *   @return _antId ID of an created
   */
  function createAnt() external returns (uint256 _antId) {
    if (eggs.balanceOf(msg.sender) < 1) revert NoEggs();

    // reincarnate ant if any, otherwise, create a new ant
    if (s_antsToReincarnate.length == 0) {
      _antId = ++s_antsCreated;
    } else {
      _antId = s_antsToReincarnate[s_antsToReincarnate.length - 1];
      s_antsToReincarnate.pop();
      s_antsCreated++;
    }

    // burn the egg
    eggs.burn(msg.sender, 1);

    // mint the ant to the user
    _mint(msg.sender, _antId);

    uint256 ovipositionPeriod = block.timestamp + PREOVIPOSITION_PERIOD;

    // ant can lay eggs in the next 10 minutes
    s_ovipositionPeriod[_antId] = ovipositionPeriod;

    emit AntCreated(msg.sender, _antId, ovipositionPeriod);
  }

  /**
   * @notice Sell an ant for `s_antPrice`. Ant is squashed but can be reincarnated.
   *   @param _antId ID of ant to sell
   */
  function sellAnt(uint256 _antId) external {
    if (_ownerOf(_antId) != msg.sender) revert NotAntOwner();

    // squash ant and queue it for reincarnation
    _squashAnt(_antId);

    uint256 antPrice = s_antPrice;

    // transfer ant price to user
    (bool success,) = msg.sender.call{value: antPrice}('');
    if (!success) revert TransferFailed();

    emit AntSold(msg.sender, _antId, antPrice);
  }

  /**
   * @notice Starts oviposition if oviposition period has been reached. Ant dying chance increases as eggs layed increases
   *   @dev Requests random numbers from Chainlink to determine number of eggs to lay and the dying chance
   *   @param _antId ID of ant to lay eggs
   *   @return requestId Request ID of random number request from Chainlink
   */
  function startOviposition(uint256 _antId) external returns (uint256 requestId) {
    if (_ownerOf(_antId) != msg.sender) revert NotAntOwner();

    uint256 ovipositionPeriod = s_ovipositionPeriod[_antId];

    // prevent oviposition before it's due
    if (block.timestamp < ovipositionPeriod) revert PreOvipositionPeriod();

    _resetOvipositionPeriod(_antId);

    if (block.timestamp >= ovipositionPeriod && block.timestamp < ovipositionPeriod + OVIPOSITION_DEADLINE) {
      // cost of request
      uint256 paid = VRF_V2_WRAPPER.calculateRequestPrice(CALLBACK_GAS_LIMIT);
      uint256 balance = linkToken.balanceOf(address(this));

      // revert if CryptoAnts cannot pay the cost
      if (balance < paid) revert InsufficientLINKTokens(balance, paid);

      // request random numbers from chainlink
      requestId = requestRandomness(CALLBACK_GAS_LIMIT, REQUEST_CONFIRMATIONS, NUM_WORDS);

      s_ovipositionRequests[requestId] =
        OvipositionRequest({paid: paid, fulfilled: false, ant: Ant({owner: msg.sender, id: _antId})});

      emit OvipositionRequested(requestId, paid);
    }
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    OvipositionRequest storage ovipositionRequest = s_ovipositionRequests[_requestId];
    Ant memory ant = ovipositionRequest.ant;

    // ensure ant wasn't squashed or transferred
    if (_ownerOf(ant.id) != ant.owner) revert NotAntOwner();

    if (ovipositionRequest.paid == 0) revert RequestNotFound(_requestId);
    ovipositionRequest.fulfilled = true;

    emit OvipositionRequestFulfilled(_requestId, ovipositionRequest.paid);

    // determine random number of eggs to lay. 10 Max
    uint256 eggsFertilized = (_randomWords[0] % MAX_EGGS_FERTILIZED) + 1;

    // determine the chance of dying. 0 - 90%
    uint256 dyingChance = (eggsFertilized * 10) - 10;

    _layEggs(ant, eggsFertilized, dyingChance, _randomWords[1]);
  }

  /// @dev Lay eggs and maybe squash ant
  function _layEggs(Ant memory ant, uint256 _eggsFertilized, uint256 _dyingChance, uint256 _randomNumber) private {
    uint256 eggsLaid;
    bool isAntDead;
    uint256 dyingChanceMeasure = _randomNumber % 100;

    // lay eggs one by one. Ants can lay at least One egg
    for (uint8 i = 0; i < _eggsFertilized; i++) {
      eggs.mint(ant.owner, 1);
      eggsLaid++;

      if (dyingChanceMeasure <= _dyingChance) {
        // squash ant and stop oviposition
        isAntDead = true;
        _squashAnt(ant.id);
        break;
      } else {
        dyingChanceMeasure--;
      }
    }

    emit EggsLaid({
      owner: ant.owner,
      antId: ant.id,
      eggsFertilized: _eggsFertilized,
      eggsLaid: eggsLaid,
      isAntDead: isAntDead
    });
  }

  function _squashAnt(uint256 _antId) private {
    _burn(_antId);

    s_antsCreated--;

    delete s_ovipositionPeriod[_antId];

    s_antsToReincarnate.push(_antId);
  }

  function _resetOvipositionPeriod(uint256 _antId) private {
    uint256 newOvipositionPeriod = block.timestamp + PREOVIPOSITION_PERIOD;

    s_ovipositionPeriod[_antId] = newOvipositionPeriod;

    emit OvipositionPeriodReset(_antId, newOvipositionPeriod);
  }

  /**
   * @notice Updates egg and ant price. Ant price must always be less than egg price
   *   @dev Only the governor can call this
   *   @param _newEggPrice New egg price
   *   @param _newAntPrice New ant price
   */
  function updatePrices(uint256 _newEggPrice, uint256 _newAntPrice) external onlyOwner {
    if (_newEggPrice == 0 || _newAntPrice == 0) revert ZeroAmount();
    if (_newAntPrice >= _newEggPrice) {
      revert AntPriceMustBeLessThanEggPrice();
    }

    s_eggPrice = _newEggPrice;
    s_antPrice = _newAntPrice;

    emit PricesUpdated(_newEggPrice, _newAntPrice);
  }

  /**
   * @notice Withdraws all ethers
   *   @dev Only the governor can call this
   *   @param _recipient Address of ether receiver
   */
  function withdrawEtherBalance(address payable _recipient) external onlyOwner {
    if (_recipient == address(0)) revert ZeroAddress();

    uint256 amount = address(this).balance;

    if (amount == 0) revert ZeroAmount();

    (bool success,) = _recipient.call{value: amount}('');
    if (!success) revert TransferFailed();
  }

  /**
   * @notice Withdraws all LINK tokens
   *   @dev Only the governor can call this
   *   @param _recipient Address of token receiver
   */
  function withdrawLinkBalance(address _recipient) external onlyOwner {
    if (_recipient == address(0)) revert ZeroAddress();

    uint256 amount = linkToken.balanceOf(address(this));

    if (amount == 0) revert ZeroAmount();

    if (!linkToken.transfer(_recipient, amount)) revert TransferFailed();
  }

  /**
   * @notice Withdraws ether
   *   @dev Only the governor can call this
   *   @param _recipient Address of ether receiver
   *   @param _amount Amount to withdraw
   */
  function withdrawEther(address payable _recipient, uint256 _amount) external onlyOwner {
    if (_recipient == address(0)) revert ZeroAddress();
    if (_amount == 0) revert ZeroAmount();
    if (address(this).balance < _amount) revert InsufficientETH();

    (bool success,) = _recipient.call{value: _amount}('');
    if (!success) revert TransferFailed();
  }

  /**
   * @notice Withdraws LINK token
   *   @dev Only the governor can call this
   *   @param _recipient Address of token receiver
   *   @param _amount Amount to withdraw
   */
  function withdrawLink(address _recipient, uint256 _amount) external onlyOwner {
    if (_recipient == address(0)) revert ZeroAddress();
    if (_amount == 0) revert ZeroAmount();

    if (!linkToken.transfer(_recipient, _amount)) revert TransferFailed();
  }

  /// @notice Gets egg price
  function getEggPrice() external view returns (uint256) {
    return s_eggPrice;
  }

  /// @notice Gets ant price
  function getAntPrice() external view returns (uint256) {
    return s_antPrice;
  }

  /// @notice Gets number of ants created
  function getAntsCreated() external view returns (uint256) {
    return s_antsCreated;
  }

  /**
   * @notice Gets oviposition period of ant
   *   @param _antId ID of ant
   */
  function getOvipositionPeriod(uint256 _antId) external view returns (uint256 ovipositionPeriod) {
    return s_ovipositionPeriod[_antId];
  }

  /**
   * @notice Gets oviposition request
   *   @param _requestId Request ID from Chainlink VRf
   */
  function getOvipositionRequest(uint256 _requestId) external view returns (OvipositionRequest memory) {
    return s_ovipositionRequests[_requestId];
  }
}
