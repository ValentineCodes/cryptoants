// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IEgg} from '../interfaces/IEgg.sol';
import {ICryptoAnts} from '../interfaces/ICryptoAnts.sol';

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

  uint256 public constant OVIPOSITION_DELAY = 3 days;
  mapping(uint256 antId => uint256 ovipositionPeriod) private s_ovipositionPeriod;

  struct Ant {
    address owner;
    uint256 id;
  }

  mapping(uint256 requestId => Ant ant) private s_ovipositionRequests;

  uint32 private constant CALLBACK_GAS_LIMIT = 100000;

  uint16 private constant REQUEST_CONFIRMATIONS = 3;

  uint32 private constant NUM_WORDS = 2;

  address private constant LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

  address private constant WRAPPER_ADDRESS = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

  constructor(address _eggs, address _governance) 
    ERC721('Crypto Ants', 'ANTS') 
    ConfirmedOwner(_governance)
    VRFV2WrapperConsumerBase(LINK_ADDRESS, WRAPPER_ADDRESS)
  {
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

    s_ovipositionPeriod[_antId] = block.timestamp + 10 minutes;

    emit AntCreated(msg.sender, _antId);
  }

  function sellAnt(uint256 _antId) external {
    if (_ownerOf(_antId) != msg.sender) revert NotAntOwner();

    _killAnt(_antId);

    (bool success,) = msg.sender.call{value: s_antPrice}('');
    if (!success) revert TransferFailed();

    emit AntSold(msg.sender, _antId);
  }

  function initOviposition(uint256 _antId) external returns (uint256 requestId) {
    if (_ownerOf(_antId) != msg.sender) revert NotAntOwner();

    uint256 ovipositionPeriod = s_ovipositionPeriod[_antId];
    if (block.timestamp < ovipositionPeriod) revert PreOvipositionPeriod();
    if(block.timestamp > ovipositionPeriod + OVIPOSITION_DELAY){
      s_ovipositionPeriod[_antId] = block.timestamp + 10 minutes;
    } else {
      requestId = requestRandomness(
        CALLBACK_GAS_LIMIT,
        REQUEST_CONFIRMATIONS,
        NUM_WORDS
      );

      s_ovipositionRequests[requestId] = Ant({
        owner: msg.sender,
        id: _antId
      });
    }
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) internal override {
    Ant memory ant = s_ovipositionRequests[_requestId];
    if(ant.owner == address(0)) revert RequestNotFound();
    
    uint256 eggsToLay = (_randomWords[0] % 10) + 1;
    uint256 dyingChance = (eggsToLay * 10) - 10;

    _layEggs(ant.owner, ant.id, eggsToLay, dyingChance, _randomWords[1]);
  }

  function _layEggs(address _owner, uint256 _antId, uint256 _eggsToLay, uint256 _dyingChance, uint256 _randomNumber) private {
    uint256 eggsLayed;
    bool willDie;
    uint256 randomNumber = _randomNumber % 100;

    for(uint8 i = 0; i < _eggsToLay; i++){
      eggs.mint(_owner, 1);
      eggsLayed++;

      if(randomNumber < _dyingChance) {
        willDie = true;
      } else {
        randomNumber--;
      }

      if(willDie){
        _killAnt(_antId);
        break;
      }
    }

    emit EggsLayed({
      owner: _owner,
      antId: _antId,
      eggsLayed: eggsLayed,
      isAntDead: willDie
    });
  } 

  function _killAnt(uint256 _antId) private {
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
  function withdrawLink(address _receiver) public onlyOwner {
    if(_receiver == address(0)) revert ZeroAddress();

    LinkTokenInterface link = LinkTokenInterface(LINK_ADDRESS);
    if(link.transfer(_receiver, link.balanceOf(address(this))) == false) revert TransferFailed();
  }

  function getEggPrice() public view returns (uint256) {
    return s_eggPrice;
  }

  function getAntPrice() public view returns (uint256) {
    return s_antPrice;
  }

  function getAntsCreated() public view returns (uint256) {
    return s_antsCreated;
  }

  function getOvipositionPeriod(uint256 _antId) external view returns (uint256 ovipositionPeriod) {
    return s_ovipositionPeriod[_antId];
  }
}
