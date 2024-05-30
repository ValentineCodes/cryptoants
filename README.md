# CryptoAnts 🐜

An NFT which enables users to own ants. Users can buy eggs. Each egg can be used to create an ant and each ant can lay an egg every 10 minutes. The ant may die while laying the eggs; The ant may not lay all it's eggs during oviposition. Users can also sell their ants for less price than the egg price.

## Deployments

GovernanceToken 
 https://sepolia.etherscan.io/address/0xA12cdD27a03C606E6cA8F3027C422B208cddcD1c

GovernanceTimeLock 
 https://sepolia.etherscan.io/address/0x27036Cf92815b2609B6C05c6bb1AAC407A77eFaf

GovernorContract  https://sepolia.etherscan.io/address/0x036b66ECB365CB4fB3C47fA638fB0576C628259c

Egg  https://sepolia.etherscan.io/address/0x304974EccfF53F74242781b8CA8904D1b0d87651

CryptoAnts  https://sepolia.etherscan.io/address/0x7A1c5E879A01dA94b04D9956e65602EF0249942D

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