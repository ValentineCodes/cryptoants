// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @dev Error when egg mint and burn is not called by the governor
error OnlyAntsContractCanCallThis();

/// @dev Error when user tries to create an ant with no eggs
error NoEggs();

/// @dev Error for 0x0 address inputs 
error ZeroAddress();

/// @dev Error when trying to create an ant that already exists
error AlreadyExists();

/// @dev Error when trying to buy eggs with the wrong amount
error WrongEtherSent();

/// @dev Error for 0 amount inputs 
error ZeroAmount();

/// @dev Error when user doesn't own the ant ID specified
error NotAntOwner();

/// @dev Error when token transfer fails
error TransferFailed();

/// @dev Error when ant price is not less than egg price
error AntPriceMustBeLessThanEggPrice();

/// @dev Error when trying to fulfill random words with a wrong request ID
/// @param requestId Request ID of random number requested from Chainlink
error RequestNotFound(uint256 requestId);

/// @dev Error when trying to start oviposition before the oviposition period
error PreOvipositionPeriod();

/// @dev Error when trying to get a random number without enough LINK tokens
error InsufficientFunds(uint256 balance, uint256 paid);