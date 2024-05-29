// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IEgg} from '../interfaces/IEgg.sol';
import {ICryptoAnts} from '../interfaces/ICryptoAnts.sol';
import '../utils/Errors.sol';

contract CryptoAnts is 
    ICryptoAnts, 
    ERC721, 
    VRFV2WrapperConsumerBase,
    ConfirmedOwner
{
  IEgg public immutable eggs;
  uint256 private s_eggPrice = 0.01 ether;
  uint256 private s_antPrice = 0.004 ether;
  uint256 private s_antsCreated = 0;
  uint256[] private s_antsToReincarnate;

  uint256 public constant MAX_EGGS_TO_LAY = 10;
  uint256 public constant PREOVIPOSITION_PERIOD = 10 minutes;
  uint256 public constant OVIPOSITION_DELAY = 3 days;
  mapping(uint256 antId => uint256 ovipositionPeriod) private s_ovipositionPeriod;

  struct Ant {
    address owner;
    uint256 id;
  }

  struct OvipositionRequest {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    Ant ant;
  }

  mapping(uint256 requestId => OvipositionRequest ovipositionRequest) private s_ovipositionRequests;

  uint32 private constant CALLBACK_GAS_LIMIT = 300000;

  uint16 private constant REQUEST_CONFIRMATIONS = 3;

  uint32 private constant NUM_WORDS = 2;

  address private immutable i_linkAddress;
  constructor(
    address _eggs, 
    address _governance,
    address _linkAddress,
    address _wrapperAddress    
  ) 
    ERC721('Crypto Ants', 'ANTS') 
    ConfirmedOwner(_governance)
    VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
  {
    eggs = IEgg(_eggs);
    i_linkAddress = _linkAddress;
  }

  function buyEggs(uint256 _amount) external payable {
    if (_amount == 0) revert ZeroAmount();
    if ((_amount * s_eggPrice) != msg.value) revert WrongEtherSent();

    eggs.mint(msg.sender, _amount);

    emit EggsBought(msg.sender, _amount);
  }

  function createAnt() external {
    if (eggs.balanceOf(msg.sender) < 1) revert NoEggs();

    uint256 _antId;

    if (s_antsToReincarnate.length == 0) {
      _antId = ++s_antsCreated;
    } else {
      _antId = s_antsToReincarnate[0];
      s_antsCreated++;
    }

    if (_ownerOf(_antId) != address(0)) revert AlreadyExists();

    eggs.burn(msg.sender, 1);

    _mint(msg.sender, _antId);

    s_ovipositionPeriod[_antId] = block.timestamp + PREOVIPOSITION_PERIOD;

    emit AntCreated(msg.sender, _antId);
  }

  function sellAnt(uint256 _antId) external {
    if (_ownerOf(_antId) != msg.sender) revert NotAntOwner();

    _squashAnt(_antId);

    (bool success,) = msg.sender.call{value: s_antPrice}('');
    if (!success) revert TransferFailed();

    emit AntSold(msg.sender, _antId);
  }

  function initOviposition(uint256 _antId) external returns (uint256 requestId) {
    if (_ownerOf(_antId) != msg.sender) revert NotAntOwner();

    uint256 ovipositionPeriod = s_ovipositionPeriod[_antId];
    if (block.timestamp < ovipositionPeriod) revert PreOvipositionPeriod();
    if(block.timestamp > ovipositionPeriod + OVIPOSITION_DELAY){
      s_ovipositionPeriod[_antId] = block.timestamp + PREOVIPOSITION_PERIOD;
    } else {
      requestId = requestRandomness(
        CALLBACK_GAS_LIMIT,
        REQUEST_CONFIRMATIONS,
        NUM_WORDS
      );

      LinkTokenInterface link = LinkTokenInterface(i_linkAddress);

      uint256 paid = VRF_V2_WRAPPER.calculateRequestPrice(CALLBACK_GAS_LIMIT);
      uint256 balance = link.balanceOf(address(this));
      if (balance < paid) revert InsufficientFunds(balance, paid);
      
      s_ovipositionRequests[requestId] = OvipositionRequest({
          paid: paid,
          fulfilled: false,
          ant: Ant({
            owner: msg.sender,
            id: _antId
          })
      });

      emit OvipositionRequested(requestId, paid);
    }
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) internal override {
    OvipositionRequest storage ovipositionRequest = s_ovipositionRequests[_requestId];
    if(ovipositionRequest.paid == 0) revert RequestNotFound(_requestId);
    ovipositionRequest.fulfilled = true;

    emit OvipositionRequestFulfilled(_requestId, ovipositionRequest.paid);
    
    uint256 eggsToLay = (_randomWords[0] % MAX_EGGS_TO_LAY) + 1;
    uint256 dyingChance = (eggsToLay * 10) - 10;

    Ant memory ant = ovipositionRequest.ant;

    _layEggs(ant.owner, ant.id, eggsToLay, dyingChance, _randomWords[1]);
  }

  function _layEggs(address _owner, uint256 _antId, uint256 _eggsToLay, uint256 _dyingChance, uint256 _randomNumber) private {
    uint256 eggsLayed;
    bool isAntDead;
    uint256 antStrength = _randomNumber % 100;

    for(uint8 i = 0; i < _eggsToLay; i++){
      eggs.mint(_owner, 1);
      eggsLayed++;

      if(antStrength <= _dyingChance) {
        isAntDead = true;
        _squashAnt(_antId);
        break;
      } else {
        antStrength--;
      }
    }

    emit EggsLayed({
      owner: _owner,
      antId: _antId,
      eggsLayed: eggsLayed,
      isAntDead: isAntDead
    });
  } 

  function _squashAnt(uint256 _antId) private {
    _burn(_antId);

    s_antsCreated--;

    delete s_ovipositionPeriod[_antId];

    s_antsToReincarnate.push(_antId);
  }

  function updatePrices(uint256 newEggPrice, uint256 newAntPrice) external onlyOwner {
    if (newEggPrice == 0 || newAntPrice == 0) revert ZeroAmount();
    if (newAntPrice >= newEggPrice) revert AntPriceMustBeLessThanEggPrice();

    s_eggPrice = newEggPrice;
    s_antPrice = newAntPrice;

    emit PricesUpdated(newEggPrice, newAntPrice);
  }

  /**
  * Allow withdraw of Link tokens from the contract
  */
  function withdrawLink(address _receiver, uint256 _amount) public onlyOwner {
    if(_receiver == address(0)) revert ZeroAddress();

    LinkTokenInterface link = LinkTokenInterface(i_linkAddress);
    if(link.transfer(_receiver, _amount) == false) revert TransferFailed();
  }

  function getEggPrice() external view returns (uint256) {
    return s_eggPrice;
  }

  function getAntPrice() external view returns (uint256) {
    return s_antPrice;
  }

  function getAntsCreated() external view returns (uint256) {
    return s_antsCreated;
  }

  function getOvipositionPeriod(uint256 _antId) external view returns (uint256 ovipositionPeriod) {
    return s_ovipositionPeriod[_antId];
  }

  function getOvipositionRequest(uint256 requestId) external view returns (OvipositionRequest memory ovipositionRequest) {
    return s_ovipositionRequests[requestId];
  }
}
