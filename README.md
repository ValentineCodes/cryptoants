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

CryptoAnts 🐜 https://sepolia.etherscan.io/address/0x9b4C2D4ECeb32DB91EB8fc3472B0cF31170A8A43

Egg 🥚 https://sepolia.etherscan.io/address/0x67F13d9E2d63e32E9be7CDEc56da1b10f4D21d9A

GovernanceToken 🪙
 https://sepolia.etherscan.io/address/0x0C538F1e4A3e23ae7E74e2D9699F767C71c51c98

GovernanceTimeLock ⏳
 https://sepolia.etherscan.io/address/0x15f9F141eD24C5b60eF1EBEa864EAE2b6Ab7Ff54

GovernorContract 🧑‍⚖️ https://sepolia.etherscan.io/address/0xEC386F7Fddee6e77E6B71817b41ffb1730B7f0EE

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