// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IEgg} from '../interfaces/IEgg.sol';

error Egg__OnlyAntsContractCanCallThis();

contract Egg is ERC20, IEgg {
  address private immutable i_ants;

  modifier onlyAntsContract() {
    if (msg.sender != i_ants) revert Egg__OnlyAntsContractCanCallThis();
    _;
  }

  constructor(address _ants) ERC20('EGG', 'EGG') {
    i_ants = _ants;
  }

  function mint(address _to, uint256 _amount) external override onlyAntsContract {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) external override onlyAntsContract {
    _burn(_from, _amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 0;
  }
}
