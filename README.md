# Alps Smart Contracts 💚

[![Truffle CI](https://github.com/AlpsFinance/alpsfinance-smart-contracts/actions/workflows/node.js.yml/badge.svg)](https://github.com/AlpsFinance/alpsfinance-smart-contracts/actions/workflows/node.js.yml)
[![NPM Publish CI](https://github.com/AlpsFinance/alpsfinance-smart-contracts/actions/workflows/publish.yml/badge.svg?branch=main)](https://github.com/AlpsFinance/alpsfinance-smart-contracts/actions/workflows/publish.yml)
![npm (scoped)](https://img.shields.io/npm/v/@alpsfinance/core)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

This is the official repository for Alps Finance Smart Contracts using Truffle Framework.

Built with 💚 from Alps Finance Developers.

## Table of Contents

- [🛠️ Pre-requisites](#%EF%B8%8F-pre-requisites)
  - [Node.js](#1-nodejs)
  - [NPM/Yarn](#2-npmyarn)
  - [Truffle CLI](#3-truffle)
  - [Moralis Admin Account](#4-moralis-admin-account)
- [👨‍💻 Getting Started](#-getting-started)
  - [Install Dependencies](#1-install-dependencies)
  - [Environment Variables](#2-environment-variables)
  - [Compile the Smart Contracts](#3-compile-the-smart-contracts)
- [🚀 Deployment](#-deployment)
- [⚗️ Testing](#%EF%B8%8F-testing)
- [📜 License](#-license)

### 🛠️ Pre-requisites

#### 1. Node.js

To install the latest version of Node.js, click [here](https://nodejs.org/en/) and follow the steps.

#### 2. NPM/Yarn

If you plan to use NPM as your package manager, then you can skip this step because NPM comes with `Node.js`. Otherwise, if you would like to use yarn, then run the following command to install yarn:

```bash
npm i -g yarn
```

#### 3. Truffle

To install truffle, run the following command:

```bash
// NPM
npm i -g truffle

// Yarn
yarn global add truffle
```

#### 4. Moralis Admin Account

To get your free Moralis Admin Account, click [here](https://admin.moralis.io/register) to register.

### 👨‍💻 Getting Started

#### 1. Install Dependencies

```sh
# NPM
npm i

# Yarn
yarn
```

#### 2. Environment Variables

Copy `.env.example` file and rename it to `.env` and fill in the environment variables.

```
ETHERSCAN_API_KEY=xxx
POLYGONSCAN_API_KEY=xxx
BSCSCAN_API_KEY=xxx
FTMSCAN_API_KEY=xxx
SNOWTRACE_API_KEY=xxx
MORALIS_SPEEDY_NODES_KEY=xxx
ARCHIVE=false
```

#### 3. Compile the Smart Contracts

```sh
# NPM
npm run compile

# Yarn
yarn compile
```

### 🚀 Deployment

In order to deploy the smart contracts, run the following command.

```sh
# NPM
npm run migrate --network <network-name>

# Yarn
yarn migrate --network <network-name>
```

where `network-name` is based on `truffle-config.js`. Once the smart contracts are successfully deployed on-chain, then optionally verify the smart contracts with the following command.

```sh
# NPM
npm run verify <smart-contract-name> --network <network-name>

# Yarn
yarn verify <smart-contract-name> --network <network-name>
```

where `smart-contract-name` is the name of the smart contract from Solidity that you would like to verify and `network-name` is similar to above.

### ⚗️ Testing

All the testing scripts are under the `test` folder. To run the test run the following commands:

```bash
// NPM
$ npm run test

// Yarn
$ yarn test
```

### 📜 License

[GNU Affero General Public License v3.0](https://github.com/AlpsFinance/alpsfinance-smart-contracts/blob/main/LICENSE)
