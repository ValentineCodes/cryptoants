// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICryptoAnts is IERC721 {
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
    error InsufficientLINKTokens(uint256 balance, uint256 paid);

    /// @dev Error when trying to transfer eth without enough balance
    error InsufficientETH();

    event EggsBought(address owner, uint256 amount);
    event AntCreated(address owner, uint256 antId, uint256 ovipositionPeriod);
    event AntSold(address owner, uint256 antId, uint256 price);
    event PricesUpdated(uint256 newEggPrice, uint256 newAntPrice);
    event EggsLaid(
        address owner,
        uint256 antId,
        uint256 eggsFertilized,
        uint256 eggsLaid,
        bool isAntDead
    );
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
    function startOviposition(
        uint256 _antId
    ) external returns (uint256 requestId);

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
    function withdrawEther(
        address payable _recipient,
        uint256 _amount
    ) external;

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
    function getOvipositionPeriod(
        uint256 _antId
    ) external view returns (uint256 ovipositionPeriod);

    /**
    @notice Gets oviposition request
    @param _requestId Request ID from Chainlink VRf
   */
    function getOvipositionRequest(
        uint256 _requestId
    ) external view returns (OvipositionRequest memory);
}
