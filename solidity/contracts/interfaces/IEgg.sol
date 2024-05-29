// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IEgg is IERC20 {
  /**
    *
    * @notice Mints {_amount} tokens to {_to}
    * @dev Only the CryptoAnts contract can call this
    * @param _to Address to mint to
    * @param _amount Amount to mint
  */
  function mint(address _to, uint256 _amount) external;

  /**
    *
    * @notice Burns {_amount} tokens from {_to}
    * @dev Only the CryptoAnts contract can call this
    * @param _from Address to burn from
    * @param _amount Amount to burn
  */
  function burn(address _from, uint256 _amount) external;
}
