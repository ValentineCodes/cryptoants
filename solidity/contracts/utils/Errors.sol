// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error OnlyAntsContractCanCallThis();

error NoEggs();

error ZeroAddress();

error AlreadyExists();

error WrongEtherSent();

error ZeroAmount();

error NotAntOwner();

error TransferFailed();

error AntPriceMustBeLessThanEggPrice();

error RequestNotFound(uint256 requestId);

error PreOvipositionPeriod();

error InsufficientFunds(uint256 balance, uint256 paid);