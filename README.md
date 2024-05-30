# CryptoAnts 🐜

An NFT which enables users to own ants. Users can buy eggs. Each egg can be used to create an ant and each ant can lay an egg every 10 minutes. The ant may die while laying the eggs; The ant may not lay all it's eggs during oviposition. Users can also sell their ants for less price than the egg price.

## Deployments

GovernanceToken 
 https://sepolia.etherscan.io/address/0x8b187d7A2Bd75a2c1C82C318963D4a2D7a3402C8

GovernanceTimeLock 
 https://sepolia.etherscan.io/address/0xa75D21DE904700AaBb5C753c3669A3b1530A04d1

GovernorContract  https://sepolia.etherscan.io/address/0xa8fF49d27e0562Ac1Be1A7232B2b996CFA9008C7

Egg  https://sepolia.etherscan.io/address/0x37E8B707747BE93cAbf90dE48F53b31AAC8466Af

CryptoAnts  https://sepolia.etherscan.io/address/0x8A911e67BFEd57C4D3f9e564b128259Da90C2697

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