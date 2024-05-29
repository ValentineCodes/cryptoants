// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IEgg} from '../interfaces/IEgg.sol';
import '../utils/Errors.sol';

contract Egg is 
  ERC20, 
  IEgg, 
  Initializable
{
  address private i_ants;

  modifier onlyAntsContract() {
    if (msg.sender != i_ants) revert OnlyAntsContractCanCallThis();
    _;
  }

  constructor() ERC20('EGG', 'EGG') {}

  function initialize(address _ants) external initializer {
    i_ants = _ants;
  }

  /**
    *
    * @notice Mints {_amount} tokens to {_to}
    * @dev Only the CryptoAnts contract can call this
    * @param _to Address to mint to
    * @param _amount Amount to mint
  */
  function mint(address _to, uint256 _amount) external override onlyAntsContract {
    _mint(_to, _amount);
  }

  /**
    *
    * @notice Burns {_amount} tokens from {_to}
    * @dev Only the CryptoAnts contract can call this
    * @param _to Address to burn from
    * @param _amount Amount to burn
  */
  function burn(address _from, uint256 _amount) external override onlyAntsContract {
    _burn(_from, _amount);
  }

  /// @notice Returns 0 so Eggs are indivisable
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }
}
