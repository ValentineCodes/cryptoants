# CryptoAnts 🐜

An NFT protocol for Ant Keeping!

## Features
- Users can buy eggs
- Users can create ants with eggs
- Users can sell their ants back to CryptoAnts
- Ants can lay eggs every 10 minutes
- Ants may die while laying eggs and may not lay all its eggs
- Governance can update egg and ant prices
- Governance can withdraw LINK token(this could disable oviposition)
- Governance can withdraw Ether(this could disable ant sales)

## Deployments

CryptoAnts 🐜 https://sepolia.etherscan.io/address/0x18921bbfaEfDC098a2F6F7C53649b4F374F91d7f

Egg 🥚 https://sepolia.etherscan.io/address/0xb088bd338C3DFf0e05F6ee4DC507FC5E0DA57cDE

GovernorContract 🧑‍⚖️ https://sepolia.etherscan.io/address/0xf0ACFf2a1A686ED5bC8DA5Ef3b9734DF0f4eA777

GovernanceToken 🪙
 https://sepolia.etherscan.io/address/0x1815829d5217817eE566b33979697ea73FC25870

GovernanceTimeLock ⏳
 https://sepolia.etherscan.io/address/0xba6a97e504C267A15ef0cd7FdF39a3e02F5C92E8

## Environment Setup

Before you begin, you need to install the following tools:

- [Node (v18 LTS)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

Then download the challenge to your computer and install dependencies by running:

```sh
git clone https://github.com/wonder-eyes/ants-ValentineCodes.git cryptoants
cd cryptoants
git checkout challenge
yarn install
```

> Run tests - `Must have data connection due to Sepolia testnet fork`

```sh
yarn test
```

> In the same terminal, deploy contracts to Sepolia testnet

Must set the enviromnent variables in foundry as specified in `.env.example` and the signers in `Deploy.sol`

```sh
yarn deploy
```

The verification of the contracts may take a couple of minutes, so be aware of that if it seems that your terminal got stuck.