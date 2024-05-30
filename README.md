# CryptoAnts 🐜

An NFT which enables users to own ants. Users can buy eggs. Each egg can be used to create an ant and each ant can lay an egg every 10 minutes. The ant may die while laying the eggs; The ant may not lay all it's eggs during oviposition. Users can also sell their ants for less price than the egg price.

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