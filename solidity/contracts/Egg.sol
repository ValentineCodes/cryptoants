// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/token/ERC20/ERC20.sol';
import {IEgg} from './interfaces/IEgg.sol';

error Egg__OnlyAntsContractCanCallThis();

contract Egg is ERC20, IEgg {
  address private s_ants;

  modifier onlyAntsContract() {
    if (msg.sender != s_ants) revert Egg__OnlyAntsContractCanCallThis();
    _;
  }

  constructor(address _ants) ERC20('EGG', 'EGG') {
    s_ants = _ants;
  }

  function mint(address _to, uint256 _amount) external override onlyAntsContract {
    _mint(_to, _amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 0;
  }
}
